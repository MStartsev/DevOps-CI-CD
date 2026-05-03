# VPC | Public & Private Subnets | Internet Gateway | NAT Gateway


# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = var.vpc_name
    ManagedBy = "Terraform"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true   # instances get public IP automatically

  tags = {
    Name      = "${var.vpc_name}-public-${count.index + 1}"
    Type      = "public"
    ManagedBy = "Terraform"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name      = "${var.vpc_name}-private-${count.index + 1}"
    Type      = "private"
    ManagedBy = "Terraform"
  }
}

# Internet Gateway (for public subnets)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.vpc_name}-igw"
    ManagedBy = "Terraform"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.vpc_name}-nat-eip"
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway - placed in first public subnet
# Single NAT GW is cost-effective for non-production.
# For HA production: create one per AZ.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name      = "${var.vpc_name}-nat-gw"
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}
