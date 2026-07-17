data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "blog_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Blog-VPC"
  }
}

# -----------------------------
# Subnets
# -----------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.blog_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.blog_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Subnet"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.blog_vpc.id

  tags = {
    Name = "Blog-IGW"
  }
}

# -----------------------------
# Elastic IP
# -----------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP"
  }
}

# -----------------------------
# NAT Gateway
# -----------------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "Blog-NAT"
  }
}

# -----------------------------
# Route Tables
# -----------------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.blog_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.blog_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private-RT"
  }
}

# -----------------------------
# Route Table Associations
# -----------------------------

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------------
# Security Groups
# -----------------------------

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.blog_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.blog_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-SG"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.blog_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "MySQL from App"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-SG"
  }
}

# -----------------------------
# EC2 Instances
# -----------------------------

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "application" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "Application"
  }
}

resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "Database"
  }
}