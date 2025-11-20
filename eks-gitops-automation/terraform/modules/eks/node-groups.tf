resource "aws_eks_node_group" "this" {
  for_each        = var.node_groups
  cluster_name    = try(aws_eks_cluster.this[0].name, data.aws_eks_cluster.existing.name)
  node_group_name = each.key
  node_role_arn   = try(aws_iam_role.eks_node_role[0].arn, data.aws_iam_role.eks_node_role.arn)
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = each.value.desired_capacity
    max_size     = each.value.max_capacity
    min_size     = each.value.min_capacity
  }

  instance_types = each.value.instance_types
  labels         = lookup(each.value, "labels", null)
  tags           = lookup(each.value, "tags", null)

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}



