# VPC and Subnets (replace with your existing VPC and Subnet IDs if you have them)
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "eks-vpc"
  }
}

# Public subnets for the NAT gateways
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "${var.region}a"
  tags = {
    Name = "eks-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "${var.region}b"
  tags = {
    Name = "eks-subnet-b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_c_cidr
  availability_zone = "${var.region}c"
  tags = {
    Name = "eks-subnet-c"
  }
}

# Private Subnets for EKS Worker Nodes and Control Plane
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "${var.region}a"
  tags = {
    Name = "eks-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "${var.region}b"
  tags = {
    Name = "eks-subnet-b"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_c_cidr
  availability_zone = "${var.region}c"
  tags = {
    Name = "eks-subnet-c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "eks-igw"
  }
}

# Route table. IGW to public internet
resource "aws_route_table" "igw_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks-public-route-table"
  }
}

# NAT Gateways (one per public subnet for high availability)
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "eks-nat-a"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  tags = {
    Name = "eks-nat-b"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.public_subnet_c.id
  tags = {
    Name = "eks-nat-c"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_a" {
  tags = {
    Name = "eks-nat-eip-a"
  }
}

resource "aws_eip" "nat_b" {
  tags = {
    Name = "eks-nat-eip-b"
  }
}

resource "aws_eip" "nat_c" {
  tags = {
    Name = "eks-nat-eip-c"
  }
}

# Private Route Table (for private subnets - routing to NAT Gateways)
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = {
    Name = "eks-private-rt-a"
  }
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_b.id
  }
  tags = {
    Name = "eks-private-rt-b"
  }
}

resource "aws_route_table" "private_rt_c" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_c.id
  }
  tags = {
    Name = "eks-private-rt-c"
  }
}

# Public route table associations for NAT gws
resource "aws_route_table_association" "public_subnet_a_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.igw_rt.id
}

resource "aws_route_table_association" "public_subnet_b_assoc" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.igw_rt.id
}

resource "aws_route_table_association" "public_subnet_c_assoc" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.igw_rt.id
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  vpc_id      = aws_vpc.vpc.id
  name_prefix = "eks-cluster-sg-"

  ingress {
    description = "Allow cluster-to-nodes communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # Allow outbound to the VPC CIDR
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

resource "aws_security_group_rule" "nodes_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow worker nodes to reach control plane"
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id      = aws_vpc.vpc.id
  name_prefix = "eks-nodes-sg-"

  # possibly restrict these for specific use cases
  ingress {
    description     = "Control plane to nodes/kubelets communication"
    from_port       = 2000
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  ingress {
    description = "Node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow outbound to the internet (via NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}
