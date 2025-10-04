locals {
  region = var.infra.aws_region
}

resource "aws_vpc" "infra_vpc" {
  cidr_block = var.infra.vpc.cidr
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-vpc"
  })
}

resource "aws_subnet" "dev_subnets" {
  for_each = var.infra.subnets
  vpc_id     = aws_vpc.infra_vpc.id
  cidr_block = each.value
  availability_zone = "${local.region}${substr(element(split("-", each.key), 1), 1, 1)}"
  map_public_ip_on_launch = startswith(each.key, "public")
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-${each.key}"
  })
}

locals {
  public_subnet_map          = { for n, s in aws_subnet.dev_subnets : n => s.id if startswith(n, "public") }
  private_subnet_map         = { for n, s in aws_subnet.dev_subnets : n => s.id if startswith(n, "private") }
  public_subnet_ids_ordered  = [for k in sort(keys(local.public_subnet_map)) : local.public_subnet_map[k]]
  nat_subnet_id              = try(local.public_subnet_map["public-1a"], local.public_subnet_ids_ordered[0])
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.infra_vpc.id
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-igw"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = local.nat_subnet_id
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.igw]
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-natgw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.infra_vpc.id
  route { 
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
    }

  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = local.public_subnet_map
  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.infra_vpc.id
  route { 
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
    }
  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each       = local.private_subnet_map
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}
