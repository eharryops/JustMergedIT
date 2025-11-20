# Optional data source if the cluster already exists
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

# Optional data source if the node IAM role already exists
data "aws_iam_role" "eks_node_role" {
  name = "${var.eks_cluster_name}-node-role"
}