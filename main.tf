
# VPC Resource
#=================================================
resource "aws_vpc" "this" {
  cidr_block           = "10.101.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = VPC_module.var.vpc_name
  }
}

# AWS internet gateway resource
#===================================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-ig"
  }
}

# AWS public subnets
#====================================================
resource "aws_subnet" "pub-sub-1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = VPC_module.var.pub-sub-1_cidr
  availability_zone       = VPC_module.var.availability_zone_1
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pub-sub-1"
  }
}

resource "aws_subnet" "pub-sub-2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = VPC_module.var.pub-sub-2_cidr
  availability_zone       = VPC_module.var.availability_zone_2
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pub-sub-2"
  }
}

# AWS private subnets
#====================================================
resource "aws_subnet" "pvt-sub-1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = VPC_module.var.pvt-sub-1_cidr
  availability_zone = VPC_module.var.availability_zone_1
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pvt-sub-1"
  }
}

resource "aws_subnet" "pvt-sub-2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = VPC_module.var.pvt-sub-2_cidr
  availability_zone = VPC_module.var.availability_zone_2
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pvt-sub-2"
  }
}

# AWS NAT gateways
#====================================================
resource "aws_eip" "nat-eip-1" {
  tags = {
    "Name" = "nat-eip-1"
  }
}

resource "aws_eip" "nat-eip-2" {
  tags = {
    "Name" = "nat-eip-2"
  }
}

resource "aws_nat_gateway" "nat-gw-1" {
  allocation_id = aws_eip.nat-eip-1.id
  subnet_id     = aws_subnet.pub-sub-1.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-nat-gw-1"
  }
}

resource "aws_nat_gateway" "nat-gw-2" {
  allocation_id = aws_eip.nat-eip-2.id
  subnet_id     = aws_subnet.pub-sub-2.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-nat-gw-2"
  }
}

# Routes and route tables
#====================================================
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pub-rt"
  }
}

resource "aws_route" "public-route-1" {
  route_table_id         = aws_route_table.pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "public-route-2" {
  route_table_id         = aws_route_table.pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "pvt-rt-1" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pvt-rt-1"
  }
}

resource "aws_route_table" "pvt-rt-2" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "${VPC_module.var.vpc_name}-pvt-rt-2"
  }
}

resource "aws_route" "private-route-1" {
  route_table_id         = aws_route_table.pvt-rt-1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw-1.id
}

resource "aws_route" "private-route-2" {
  route_table_id         = aws_route_table.pvt-rt-2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw-2.id
}

resource "aws_route_table_association" "pub-sub-1-assoc" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "pub-sub-2-assoc" {
  subnet_id      = aws_subnet.pub-sub-2.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "pvt-sub-1-assoc" {
  subnet_id      = aws_subnet.pvt-sub-1.id
  route_table_id = aws_route_table.pvt-rt-1.id
}

resource "aws_route_table_association" "pvt-sub-2-assoc" {
  subnet_id      = aws_subnet.pvt-sub-2.id
  route_table_id = aws_route_table.pvt-rt-2.id
}
##################################################################

# EC2 instace
# ===========================
resource "aws_security_group" "aws_sg" {
  name = "public-web-sg"

  ingress {
    description = "SSH from the internet"
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
}
resource "aws_instance" "aws_ins" {
  ami                         = ec2_module.var.ami-type  # Ubuntu AMI ID
  instance_type               = ec2_module.var.instance_type
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]  # Attach the security group to the instance
  associate_public_ip_address = true
  key_name                    = ec2_module.var.key-name  # Replace with your key pair name

  tags = {
    Name = "My-instance"
  }
}
