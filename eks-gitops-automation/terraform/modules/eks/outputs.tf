output "eks_cluster_name" {
  value = try(aws_eks_cluster.this[0].name, data.aws_eks_cluster.existing.name)
}
