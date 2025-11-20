# GitHub Actions Workflow Guide

## Overview

This project includes a GitHub Actions workflow (`cluster-dispatch.yaml`) that automates the deployment of EKS clusters with built-in safety checks and cluster limit enforcement.

## Workflow Features

- **Cluster Limit Enforcement** - Maximum 2 clusters per AWS account  
- **Existing Cluster Support** - Automatically detects and imports existing clusters  
- **Terraform State Management** - Handles import of existing resources  
- **Auto-cleanup on Failure** - Destroys resources if deployment fails  
- **Manual Trigger** - Workflow dispatch allows on-demand deployments

---

## Prerequisites

### GitHub Secrets Required

Add these secrets to your GitHub repository:

1. **`AWS_ACCESS_KEY_ID`** - Your AWS access key
2. **`AWS_SECRET_ACCESS_KEY`** - Your AWS secret key

**To add secrets:**
1. Go to your repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret

---

## How to Use the Workflow

### Option 1: Via GitHub UI

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Deploy Cluster** workflow
4. Click **Run workflow** button
5. Enter cluster name (or use default: `main-eks`)
6. Click **Run workflow**

### Option 2: Via GitHub CLI

```bash
gh workflow run cluster-dispatch.yaml -f cluster_name=my-cluster
```

---

## Workflow Steps Explained

### 1. **Checkout Repository**
Clones the repo to the GitHub Actions runner

### 2. **Configure AWS Credentials**
Authenticates with AWS using your secrets

### 3. **Setup Terraform**
Installs Terraform v1.6.5

### 4. **Check Cluster Limit**
- Queries AWS for existing EKS clusters
- **Fails if 2+ clusters already exist**
- Lists existing clusters for reference

### 5. **Initialize Terraform**
Runs `terraform init` to prepare modules

### 6. **Check if Cluster Exists**
- Checks if the specified cluster name already exists
- Sets output variable for conditional logic

### 7. **Import Existing Cluster** (conditional)
- **Only runs if cluster exists**
- Imports cluster and IAM roles into Terraform state
- Uses `|| true` to ignore import errors (resource may already be in state)

### 8. **Terraform Apply**
- Creates new cluster if it doesn't exist
- Updates existing cluster if already in state

### 9. **Cleanup on Failure** (conditional)
- **Only runs if any previous step fails**
- Runs `terraform destroy` to clean up partial deployments

---

## Cluster Limit Logic

The workflow enforces a **maximum of 2 clusters** to prevent cost overruns:

```yaml
MAX_CLUSTERS=2
CLUSTER_COUNT=$(aws eks list-clusters --query 'clusters | length(@)')

if [ "$CLUSTER_COUNT" -ge "$MAX_CLUSTERS" ]; then
  exit 1  # Workflow fails
fi
```

**If limit is reached:**
- Workflow fails immediately
- Lists existing clusters
- Provides instructions to delete a cluster or use existing

---

## Using Existing Clusters

The workflow **automatically detects** existing clusters:

```bash
# Workflow checks if cluster exists
aws eks describe-cluster --name "$CLUSTER_NAME"

# If exists: imports to Terraform state
terraform import module.eks.aws_eks_cluster.this[0] "$CLUSTER_NAME"
```

**This means:**
- You can run the workflow against an existing cluster
- Terraform will manage it going forward
- No duplicate resources created

---

## Local Deployment Guide

You can run the entire deployment process locally without GitHub Actions. This is useful for development and testing.

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform v1.6+
- kubectl
- Python 3

### Step 1: Configure Repository
Run the configuration script to set up your username in the manifests:
```bash
./scripts/configure-repo.sh
```

### Step 2: Provision Infrastructure
Use Terraform to create the EKS cluster and networking:
```bash
cd terraform/infra
terraform init
terraform apply -auto-approve
```

### Step 3: Configure kubectl
Connect to your new cluster:
```bash
aws eks update-kubeconfig --name main-eks --region us-east-1
```

### Step 4: Deploy Applications
Use the Python script to deploy ArgoCD and applications based on `app-of-apps.yaml`:
```bash
cd ../..  # Return to project root
python3 scripts/apply-apps.py
```

### Step 5: Cleanup (Optional)
To destroy the cluster and save costs:
```bash
cd terraform/infra
terraform destroy -auto-approve
```

---

## Workflow Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `cluster_name` | Name of the EKS cluster | No | `main-eks` |

**Example with custom name:**
```bash
gh workflow run cluster-dispatch.yaml -f cluster_name=production-eks
```

---

## Troubleshooting

### "Maximum cluster limit reached"

**Problem:** You already have 2 clusters

**Solution:**
```bash
# List clusters
aws eks list-clusters --region us-east-1

# Delete a cluster
aws eks delete-cluster --name old-cluster --region us-east-1

# Wait for deletion (can take 10-15 minutes)
aws eks describe-cluster --name old-cluster --region us-east-1
```

### "Terraform import failed"

**Problem:** Resource already in state or doesn't exist

**Solution:** This is usually safe to ignore (workflow uses `|| true`)

### "Terraform apply failed"

**Problem:** Infrastructure creation error

**Solution:** 
- Check the workflow logs for specific error
- Cleanup happens automatically via "Cleanup on Failure" step
- Fix the issue and re-run workflow

---

## Cost Considerations

**EKS Cluster Costs:**
- Control plane: ~$0.10/hour (~$73/month)
- Worker nodes: Depends on instance type (t3.micro in free tier)

**2-Cluster Limit Rationale:**
- Prevents accidental cost overruns
- Encourages proper cleanup
- Suitable for learning/demo purposes

**For production:** Adjust `MAX_CLUSTERS` in the workflow

---

## Security Best Practices

1. **Use IAM roles** instead of access keys (for production)
2. **Enable MFA** on AWS account
3. **Rotate secrets** regularly
4. **Use least-privilege** IAM policies
5. **Enable CloudTrail** for audit logging

---

## Next Steps

After the workflow completes:

1. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --name main-eks --region us-east-1
   ```

2. **Verify cluster:**
   ```bash
   kubectl get nodes
   ```

3. **Install ArgoCD** (manual or via another workflow)

4. **Deploy applications** via GitOps

---

## Workflow File Location

`.github/workflows/cluster-dispatch.yaml`

**To modify:**
1. Edit the file in your repo
2. Commit and push changes
3. Workflow updates automatically
