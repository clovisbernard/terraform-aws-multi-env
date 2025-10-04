output "vpc_id" {
  value = aws_vpc.infra_vpc.id
}

output "subnet_ids_by_name" {
  value = { for name, s in aws_subnet.dev_subnets : name => s.id }
}

output "nat_eip_public_ip" {
  value = aws_eip.nat.public_ip
}

output "public_route_table_id"  { value = aws_route_table.public.id }
output "private_route_table_id" { value = aws_route_table.private.id }
