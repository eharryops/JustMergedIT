module "network" {
  source             = "../modules/network"
  eks_cluster_name = "main-eks"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs= ["10.0.3.0/24", "10.0.4.0/24"]
  aws_region         = "us-east-1"
  azs                = ["us-east-1a", "us-east-1b"]
}

module "eks" {
  source           = "../modules/eks"
  eks_cluster_name = "main-eks"
  subnet_ids       = concat(
    module.network.public_subnet_ids,
    module.network.private_subnet_ids
  )

  node_groups = {
    default = {
      desired_capacity = 5
      max_capacity     = 6
      min_capacity     = 2
      instance_types   = ["t3.micro"]
    }
  }
}