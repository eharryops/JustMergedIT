variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of node group configurations for the EKS cluster"
  type = map(object({
    desired_capacity = number
    max_capacity     = number
    min_capacity     = number
    instance_types   = list(string)
  }))
  default = {}
}

variable "skip_cluster_creation" {
  description = "Skip creating the cluster if it already exists"
  type        = bool
  default     = false
}
