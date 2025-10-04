output "vpc_id"               { value = module.vpc.vpc_id }
output "subnet_ids_by_name"   { value = module.vpc.subnet_ids_by_name }
output "nat_eip_public_ip"    { value = module.vpc.nat_eip_public_ip }
output "ec2_instance_id"      { value = module.compute.instance_id }
output "ec2_private_ip"       { value = module.compute.private_ip }
output "db_identifier"        { value = module.database.db_identifier }
output "db_endpoint"          { value = module.database.db_endpoint }
output "db_port"              { value = module.database.db_port }

