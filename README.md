# terraform-aws-multi-env

Modular **Terraform** stack for **AWS** — VPC, public/private subnets, IGW/NAT, **EC2 in private subnets**, and **MSSQL RDS** — all **YAML-driven** with clean **dev/prod isolation** using separate **local state files** (no workspaces).

---

##  What this provides

* **Networking**

  * 1× VPC
  * 2× public + 2× private subnets
  * Internet Gateway, NAT Gateway, route tables & associations
* **Compute**

  * 1× EC2 instance launched **in a private subnet**
* **Database**

  * 1× RDS **SQL Server (Standard Edition)** in private subnets (always enabled in this repo)
* **Config via YAML**

  * `envs/dev.yaml` and `envs/prod.yaml` hold CIDRs, EC2, DB, and tags
* **Environment isolation**

  * Separate **local backend** paths: one state file per env (no workspaces)
  * Tags automatically reflect the selected env (dev/prod)

---

##  Repository layout

```
├── envs
│   ├── dev.yaml
│   └── prod.yaml
├── modules
│   ├── compute
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── database
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── networking
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── README.md
├── resources
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
└── states
    ├── dev
    │   ├── terraform.tfstate
    │   └── terraform.tfstate.backup
    └── prod
        ├── terraform.tfstate
        └── terraform.tfstate.backup
```

---

##  Prerequisites

* **Terraform** ≥ 1.6
* **AWS credentials** available to Terraform (env vars, profile, or SSO)
* An existing **EC2 key pair** in the target region (matches `ec2.key_name` in YAML)

---

##  Configuration

Edit `infra/envs/dev.yaml` and `infra/envs/prod.yaml`:

---

##  One-time setup

```bash
cd infra/resources
mkdir -p ../states/dev ../states/prod
```

---

##  Create / Update

> Always run from `infra/resources`. The `env` variable picks the YAML file. The backend path keeps state separated.

### DEV

```bash
terraform init -reconfigure -backend-config="path=../states/dev/terraform.tfstate"
terraform plan  -var="env=dev"
terraform apply -var="env=dev" -auto-approve
```

### PROD

```bash
terraform init -reconfigure -backend-config="path=../states/prod/terraform.tfstate"
terraform plan  -var="env=prod"
terraform apply -var="env=prod" -auto-approve
```

**Outputs to verify**

```bash
terraform output vpc_id
terraform output subnet_ids_by_name
terraform output ec2_private_ip
terraform output db_endpoint
```

---

##  Destroy

**RDS snapshot rule:**

* For quick teardown in non-prod, set in the DB resource: `deletion_protection = false` and `skip_final_snapshot = true`.
* If you want a final snapshot, set `skip_final_snapshot = false` and provide `final_snapshot_identifier`.

### DEV

```bash
terraform init -reconfigure -backend-config="path=../states/dev/terraform.tfstate"
# Optional: reconcile if you deleted anything by hand
terraform apply -refresh-only -var="env=dev" -auto-approve
terraform destroy -var="env=dev" -auto-approve
```

### PROD

```bash
terraform init -reconfigure -backend-config="path=../states/prod/terraform.tfstate"
terraform apply -refresh-only -var="env=prod" -auto-approve
terraform destroy -var="env=prod" -auto-approve
```

---

##  Tagging behavior

Terraform merges your YAML `tags` with `{ environment = var.env }`, so the **effective `environment` tag always matches** the env you run (`dev` or `prod`) even if the YAML has it blank or set differently.

---

##  How env selection works

In `resources/main.tf`:

```hcl
variable "env" { type = string }  # "dev" or "prod"

locals {
  config     = yamldecode(file("${path.module}/../envs/${var.env}.yaml"))
  tags_final = merge(local.config.tags, { environment = var.env }) # last map wins
  # ...
}
```

* `-var="env=dev"` → loads `envs/dev.yaml`
* `-var="env=prod"` → loads `envs/prod.yaml`

---

##  Troubleshooting

* **Plan shows `subnet_ids_by_name = {}` / errors selecting subnets**

  * You’re likely on the wrong state path or using a refresh-only plan.
  * Re-init to the correct env state and run a normal plan/apply.

* **Destroy fails with** `final_snapshot_identifier is required`

  * Set `skip_final_snapshot = true` (or provide `final_snapshot_identifier`) and re-apply, then destroy.

* **Duplicate stacks**

  * Happens if you applied with a different state path. Always re-init with the correct `-backend-config="path=..."` before any plan/apply.

* **Costs**

  * NAT Gateway and SQL Server RDS incur meaningful costs. Destroy idle envs or swap dev to cheaper patterns if needed.


##  License