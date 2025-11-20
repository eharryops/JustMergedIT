# Check if cluster exists
data "aws_eks_cluster" "existing" {
  name     = var.eks_cluster_name
  # optional = true
}

data "aws_eks_cluster_auth" "existing" {
  name = var.eks_cluster_name
}

# IAM Roles (create only if cluster does NOT exist)
resource "aws_iam_role" "eks_cluster_role" {
  # If the cluster already exists, don't create; else create
  count = can(data.aws_eks_cluster.existing.id) ? 0 : 1
  name = "${var.eks_cluster_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role" "eks_node_role" {
# If the cluster already exists, don't create; else create
  count = can(data.aws_eks_cluster.existing.id) ? 0 : 1
  name = "${var.eks_cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

# Attach policies if roles created
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  count = length(aws_iam_role.eks_cluster_role)
  role  = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSNodePolicy" {
  count = length(aws_iam_role.eks_node_role)
  role  = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  count = length(aws_iam_role.eks_node_role)
  role  = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  count = length(aws_iam_role.eks_node_role)
  role  = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster (create if not exists)
resource "aws_eks_cluster" "this" {
  count = can(data.aws_eks_cluster.existing.id) ? 0 : 1
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn
  version  = var.eks_version

  vpc_config {
    subnet_ids             = var.subnet_ids
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}


