provider "aws" {
  region = "us-east-1"  # Defina a região desejada
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Substitua pelo CIDR desejado
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"  # Substitua pelo CIDR desejado para a subnet
  availability_zone       = "us-east-1a"    # Substitua pela zona de disponibilidade desejada

  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"  # Substitua pelo CIDR desejado para a subnet
  availability_zone       = "us-east-1a"    # Substitua pela zona de disponibilidade desejada

  map_public_ip_on_launch = false
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_public.id  # Certifique-se de criar o recurso do Internet Gateway (exemplo abaixo)
  }
}

resource "aws_route_table_association" "association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_internet_gateway" "ig_public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng_private.id  # Certifique-se de criar o recurso do NAT Gateway (exemplo abaixo)
  }
}

resource "aws_route_table_association" "association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_nat_gateway" "ng_private" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.subnet_private.id
}