# EKS Cluster resource
resource "aws_eks_cluster" "development" {
  name     = "development-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [

      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id,
      aws_subnet.private_subnet_c.id,
    ]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_subnet.private_subnet_a,
    aws_subnet.private_subnet_b,
    aws_subnet.private_subnet_c,
  ]
}

# Launch template that specifies the SG
data "aws_ami" "eks_worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"]
  }

  owners = ["602401143452"]
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-x86-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-x86-node"
    }
  }
}

# EKS Node Group resource
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.development.name
  node_group_name = "eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id,
    aws_subnet.private_subnet_c.id,
  ]

  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 3
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  capacity_type = "SPOT"

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_eks_cluster.development,
    aws_subnet.private_subnet_a,
    aws_subnet.private_subnet_b,
    aws_subnet.private_subnet_c,
    aws_security_group.eks_nodes_sg, # Ensure SG is created first
  ]
}

data "aws_eks_cluster_auth" "development" {
  name = aws_eks_cluster.development.name
}
