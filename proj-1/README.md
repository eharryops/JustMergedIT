# AWS Infrastructure as Code & GitOps Showcase

This project demonstrates modern cloud infrastructure automation using **Terraform**, **AWS**, and **GitOps** principles. The repository is structured to provision a secure, production-ready AWS environment, deploy an EKS (Kubernetes) cluster, and integrate ArgoCD for continuous delivery.

## What You'll Accomplish

- **Automated AWS Networking:**  
  Use Terraform to declaratively provision VPCs, public/private subnets, gateways, route tables, and security groups.
- **Kubernetes Cluster Creation:**  
  Deploy an EKS cluster using Terraform modules, ensuring best practices for multi-AZ, scalable, and secure architecture.
- **GitOps with ArgoCD:**  
  Integrate ArgoCD into the EKS cluster to enable automated, version-controlled application deployments directly from Git.
- **End-to-End Automation:**  
  The workflow—from infrastructure to cluster to GitOps—enables repeatable, auditable, and hands-off cloud operations.

## Workflow Overview

1. **Infrastructure Provisioning:**  
   - Run `terraform init`, `terraform plan`, and `terraform apply` to create all AWS resources.
   - Modular `.tf` files ensure resources are organized and maintainable.

2. **Cluster Bootstrapping:**  
   - Terraform automates EKS cluster creation, including node groups and IAM roles.
   - Outputs from networking modules are used to configure the cluster securely across multiple AZs.

3. **GitOps Enablement:**  
   - ArgoCD is installed into the EKS cluster (via Helm or manifests).
   - Application manifests are managed in Git; ArgoCD syncs cluster state to match repository changes.

4. **Continuous Automation:**  
   - Any change to infrastructure or application code is tracked in Git and automatically applied via Terraform and ArgoCD.
   - This ensures infrastructure and workloads are always up-to-date, consistent, and recoverable.

## Why This Matters

- **Declarative Infrastructure:**  
  Everything is defined as code—no manual steps, no drift.
- **Security & Scalability:**  
  AWS best practices (multi-AZ, least privilege, tagging) are baked in.
- **GitOps:**  
  ArgoCD brings auditability, rollback, and self-healing to application delivery.
- **DevOps Ready:**  
  The workflow supports rapid iteration, safe deployments, and easy onboarding for teams.

---

For details on architecture, module usage, and developer workflows, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md).
