#create vpc as a module and call the module to the project directory
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.project_name}-${var.project_env}",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}-${var.project_env}",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.az.names[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, 0)
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}-${var.project_env}-public1",
    project = var.project_name,
    env     = var.project_env
  }
}


resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.az.names[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, 1)
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}-${var.project_env}-public2",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.az.names[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, 2)
  map_public_ip_on_launch = false
  tags = {
    Name    = "${var.project_name}-${var.project_env}-private1",
    project = var.project_name,
    env     = var.project_env
  }
}


resource "aws_eip" "ngw" {
  vpc = true
  tags = {
    Name    = "${var.project_name}-${var.project_env}-nat",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public2.id
  tags = {
    Name    = "${var.project_name}-${var.project_env}",
    project = var.project_name,
    env     = var.project_env
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project_name}-${var.project_env}-public",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name    = "${var.project_name}-${var.project_env}-private",
    project = var.project_name,
    env     = var.project_env
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
