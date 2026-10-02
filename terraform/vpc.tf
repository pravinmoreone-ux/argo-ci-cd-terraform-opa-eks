resource "aws_vpc" "main" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "argo-ci-cd-vpc"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.30.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "argo-ci-cd-public-a"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.30.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "argo-ci-cd-public-b"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.30.11.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name        = "argo-ci-cd-private-a"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.30.12.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "argo-ci-cd-private-b"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "argo-ci-cd-igw"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "argo-ci-cd-public-rt"
    Environment = var.environment
    Project     = "argo-ci-cd"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
