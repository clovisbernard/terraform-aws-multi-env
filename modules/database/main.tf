locals {
  engine     = lower(var.config.sql_db.engine) == "sqlse" ? "sqlserver-se" : var.config.sql_db.engine
  db_class   = length(trimspace(var.config.sql_db.db_instance_class)) > 0 ? var.config.sql_db.db_instance_class : "db.m6i.large"
  identifier = "${var.config.tags["environment"]}-${var.config.tags["project"]}-mssql"
  base_tags  = merge(var.config.tags, { Name = local.identifier })
}

resource "aws_security_group" "db" {
  name        = "${local.identifier}-sg"
  description = "MSSQL RDS access from within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow SQL Server access from VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.base_tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.identifier}-subnets"
  subnet_ids = var.subnet_ids
  tags       = local.base_tags
}

resource "aws_db_instance" "mssql" {
  identifier     = local.identifier
  skip_final_snapshot = true
  engine         = local.engine                
  license_model  = "license-included"          
  instance_class = local.db_class
  username = var.config.sql_db.username
  password = var.config.sql_db.password
  allocated_storage = var.config.sql_db.allocated_storage
  storage_type      = "gp3"
  iops              = var.config.sql_db.iops
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az            = var.config.sql_db.multi_az
  publicly_accessible = var.config.sql_db.publicly_accessible
  deletion_protection = var.config.sql_db.deletion_protection
  monitoring_interval = var.config.sql_db.create_monitoring_role ? var.config.sql_db.monitoring_interval : 0
  performance_insights_enabled = var.config.sql_db.performance_insights_enabled
  parameter_group_name         = var.config.sql_db.parameter_group_name
  availability_zone = var.config.sql_db.multi_az ? null : var.config.sql_db.availability_zone
  storage_encrypted       = true
  backup_retention_period = 7
  tags = local.base_tags
}
