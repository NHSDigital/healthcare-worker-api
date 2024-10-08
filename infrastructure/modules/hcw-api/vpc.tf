resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "hcw-app-vpc-${var.env}"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone_id = "euw2-az1"
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone_id = "euw2-az2"
}

resource "aws_subnet" "subnet_c" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone_id = "euw2-az3"
}

resource "aws_security_group" "app_security_group" {
  name   = "hcw-app-sg-${var.env}"
  vpc_id = aws_vpc.app_vpc.id
}
