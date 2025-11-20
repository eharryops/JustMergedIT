## Kubernetes Manifest Management Guide

This project uses **Kustomize** for managing Kubernetes manifests instead of Helm. This approach provides:
- Native Kubernetes YAML (no templating language to learn)
- Better GitOps compatibility
- Easier to understand and debug
- More control over resource management

---

## Directory Structure

```
k8s-apps/
├── argocd/                    # ArgoCD installation
│   ├── kustomization.yaml     # Kustomize config
│   └── patches/               # Customizations
├── argocd-apps/               # ArgoCD Application definitions
│   ├── app-of-apps.yaml              # Centralized app enable/disable config
│   ├── karpenter.yaml         # Karpenter deployment
│   └── cert-manager.yaml      # Cert-manager deployment
└── manifests/                 # Raw Kubernetes manifests
    ├── karpenter/
    └── cert-manager/
```

---

## Bootstrap Process

### 1. Install ArgoCD

ArgoCD is installed using Kustomize during the Terraform deployment:

```bash
kubectl apply -k k8s-apps/argocd/
```

This:
- Installs ArgoCD from the official manifest
- Applies patches to expose the UI via LoadBalancer
- Configures insecure mode for easier access

### 2. Deploy Applications (Selective)

Instead of using ArgoCD's app-of-apps pattern, we use a **custom deployment script** that reads `app-of-apps.yaml`:

```bash
# Automated (GitHub Actions)
python3 scripts/apply-apps.py

# Manual
kubectl apply -f k8s-apps/argocd-apps/karpenter.yaml
kubectl apply -f k8s-apps/argocd-apps/cert-manager.yaml
```

This approach:
- Deploys only applications marked as `enabled: true` in `app-of-apps.yaml`
- Provides fine-grained control for testing and development
- Avoids deploying all apps when you only need one
- Supports environment-specific configurations

### 3. Continuous Sync

ArgoCD monitors Git repository:
- Detects changes to manifests
- Automatically syncs cluster state
- Self-heals if manual changes are made

---

## Kustomize Patterns Used

### Pattern 1: Remote Base + Local Patches

**Use case:** Install official tools with customizations

```yaml
# k8s-apps/argocd/kustomization.yaml
resources:
  - https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.3/manifests/install.yaml

patches:
  - patch: |-
      - op: replace
        path: /spec/type
        value: LoadBalancer
    target:
      kind: Service
      name: argocd-server
```

**Benefits:**
- Always use official manifests
- Minimal maintenance
- Easy upgrades (change URL version)

### Pattern 2: Remote CRDs + Local Resources

**Use case:** Install operators with custom configuration

```yaml
# k8s-apps/manifests/karpenter/kustomization.yaml
resources:
  # Remote CRDs
  - https://raw.githubusercontent.com/aws/karpenter/v0.32.0/pkg/apis/crds/...
  
  # Local resources
  - deployment.yaml
  - provisioner.yaml
  - serviceaccount.yaml
```

**Benefits:**
- Official CRDs (always compatible)
- Custom deployment config
- Environment-specific settings

### Pattern 3: ConfigMap Generation

**Use case:** Dynamic configuration

```yaml
configMapGenerator:
  - name: karpenter-global-settings
    literals:
      - aws.clusterName=main-eks
      - aws.clusterEndpoint=https://...
```

**Benefits:**
- No hardcoded values in manifests
- Easy to override per environment
- Automatic hash suffix (triggers pod restart on change)

---

## Comparison: Kustomize vs Helm

| Feature | Kustomize | Helm |
|---------|-----------|------|
| **Learning Curve** | Low (just YAML) | Medium (templates + values) |
| **Templating** | Patches & overlays | Go templates |
| **Dependencies** | None (built into kubectl) | Helm CLI required |
| **ArgoCD Support** | Native | Supported but adds complexity |
| **Debugging** | Easy (see exact YAML) | Harder (template rendering) |
| **Reusability** | Overlays | Charts |
| **Best For** | GitOps, simple apps | Complex apps, package distribution |

**Our Choice:** Kustomize - Better for GitOps and learning

---

## Customization Examples

### Example 1: Change ArgoCD Service Type

**File:** `k8s-apps/argocd/kustomization.yaml`

```yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/type
        value: ClusterIP  # Changed from LoadBalancer
    target:
      kind: Service
      name: argocd-server
```

### Example 2: Add Environment-Specific Config

**File:** `k8s-apps/manifests/karpenter/kustomization.yaml`

```yaml
configMapGenerator:
  - name: karpenter-global-settings
    literals:
      - aws.clusterName=production-eks  # Environment-specific
      - aws.defaultInstanceProfile=ProdKarpenterProfile
```

### Example 3: Adjust Resource Limits

**File:** `k8s-apps/manifests/karpenter/deployment.yaml`

```yaml
resources:
  requests:
    cpu: 200m      # Increased from 100m
    memory: 512Mi  # Increased from 256Mi
  limits:
    cpu: 1000m     # Increased from 500m
    memory: 1Gi    # Increased from 512Mi
```

---

## Deployment Workflow

### Initial Setup

```bash
# 1. Infrastructure: Terraform creates EKS cluster
cd terraform/infra
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --name main-eks --region us-east-1

# 3. Install ArgoCD
kubectl apply -k ../../k8s-apps/argocd/

# 4. Wait for ArgoCD
kubectl wait --for=condition=available deployment/argocd-server -n argocd

# 5. Deploy app-of-apps
kubectl apply -f ../../k8s-apps/argocd-apps/app-of-apps.yaml
```

### Making Changes

```bash
# 1. Edit manifest
vim k8s-apps/manifests/karpenter/provisioner.yaml

# 2. Commit and push
git add .
git commit -m "Update Karpenter provisioner"
git push

# 3. ArgoCD automatically syncs (if automated)
# Or manually sync in ArgoCD UI
```

---

## Best Practices

### DO

1. Use official manifests as base (via URL)
2. Keep patches minimal - only change what's needed
3. Version pin remote resources (use specific tags/versions)
4. Use namespaces to isolate applications
5. ArgoCD Install: GitHub Action installs ArgoCD
6. Git is Truth: Never apply changes manually with `kubectl` (except for debugging).
7. Test locally with `kubectl apply -k --dry-run=client`

### DON'T

1. Don't copy entire manifests - reference official sources
2. Secrets Management: Never commit secrets to Git. Use External Secrets or Sealed Secrets.
3. Don't mix Helm and Kustomize in same app (pick one)
4. Don't skip validation - always test before pushing
5. Don't ignore ArgoCD health - monitor sync status

---

## Debugging

### 1. Base & Overlays (Kustomize)
```bash
# See what Kustomize will generate
kubectl kustomize k8s-apps/argocd/

# See what will be applied
kubectl apply -k k8s-apps/argocd/ --dry-run=client -o yaml
```

### Check ArgoCD Sync Status

```bash
# List all applications
kubectl get applications -n argocd

# Describe specific app
kubectl describe application karpenter -n argocd

# View sync errors
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Validate Manifests

```bash
# Lint YAML
yamllint k8s-apps/

# Validate Kubernetes resources
kubectl apply -k k8s-apps/argocd/ --dry-run=server --validate=true
```

---

## Learning Resources

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kubernetes Patterns](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)

---

## Migration from Helm

If you have existing Helm charts:

### Option 1: Keep Helm (ArgoCD Helm Support)

```yaml
# ArgoCD Application using Helm
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://charts.example.com
    chart: my-app
    targetRevision: 1.0.0
    helm:
      values: |
        key: value
```

### Option 2: Convert to Kustomize

```bash
# Render Helm chart to YAML
helm template my-app charts/my-app > manifests/my-app/base.yaml

# Create kustomization
cat <<EOF > manifests/my-app/kustomization.yaml
resources:
  - base.yaml
EOF
```

**Our Recommendation:** Start with Kustomize for new projects

---

## Summary

**This project uses:**
- Small PRs: Keep changes small and atomic.
- ArgoCD Applications for GitOps
- App-of-Apps pattern for centralized management
- Immutable Tags: Use specific image tags (e.g., `v1.2.3`), never `latest`.
- Local overlays for customization

**Result:** Clean, maintainable, GitOps-native infrastructure!
```
