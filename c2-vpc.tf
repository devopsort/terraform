# Resources Block
# Resource-1: Create VPC
resource "aws_vpc" "vpc-obligatorio" {
  cidr_block = var.VPC_cidr_block //"10.0.0.0/16"
  tags = {
    "Name" = "vpc-obligatorio"
  }
}


resource "aws_subnet" "vpc-subnets-obl" {
  vpc_id            = aws_vpc.vpc-obligatorio.id
  for_each = var.subnet_data
    availability_zone = each.value.availability_zone
    map_public_ip_on_launch = true
    cidr_block        = each.value.cidr_block
    tags = each.value.tags
}


# Resource-3: Internet Gateway
resource "aws_internet_gateway" "vpc-obligatorio-igw" {
  vpc_id = aws_vpc.vpc-obligatorio.id
}

# Resource-4: Create Route Table
resource "aws_route_table" "vpc-obligatorio-public-route-table" {
  vpc_id = aws_vpc.vpc-obligatorio.id
}

# Resource-5: Create Route in Route Table for Internet Access
resource "aws_route" "vpc-obligatorio-public-route" {
  route_table_id         = aws_route_table.vpc-obligatorio-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-obligatorio-igw.id
}

# Resource-6: Associate the Route Table with the Subnet a
resource "aws_route_table_association" "vpc-obligatorio-frontend-route-table-associate" {
  for_each = var.subnet_data
    route_table_id = aws_route_table.vpc-obligatorio-public-route-table.id
    subnet_id      = aws_subnet.vpc-subnets-obl[each.key].id
}


/*
# Resource-6: Associate the Route Table with the Subnet a
resource "aws_route_table_association" "vpc-obligatorio-frontend-route-table-associate" {
  for_each = var.subnet_numbers
    route_table_id = aws_route_table.vpc-obligatorio-public-route-table.id
    subnet_id      = aws_subnet.vpc-subnets-obl[each.key].id
}

*/






