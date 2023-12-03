provider "aws" {
  region = "us-east-1"  # Defina a região desejada
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Substitua pelo CIDR desejado
}

