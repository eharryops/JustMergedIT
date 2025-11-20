# Centralized Application Management with app-of-apps.yaml

## Overview

The `app-of-apps.yaml` file is the **single source of truth** for managing applications in your EKS cluster. Instead of using ArgoCD's app-of-apps pattern (which deploys everything in a directory), we use a custom approach that gives you fine-grained control over which applications are deployed.

### Why Not App-of-Apps?

ArgoCD's app-of-apps pattern automatically deploys all `.yaml` files in a directory. This is problematic when:
- Testing a single app among 15+ applications
- Managing different environments (dev/staging/prod)
- Temporarily disabling apps without deleting files

Our `app-of-apps.yaml` approach lets you enable/disable apps with a simple flag change.

## File Location

```
k8s-apps/argocd-apps/app-of-apps.yaml
```

## Format

```yaml
applications:
  app-name:
    enabled: true/false      # Controls if app is deployed
    description: "..."       # Human-readable description
    manifestPath: "..."      # Path to ArgoCD Application YAML
```

## Example

```yaml
applications:
  karpenter:
    enabled: true
    description: "Kubernetes node autoscaler for cost-effective scaling"
    manifestPath: "karpenter.yaml"
    
  cert-manager:
    enabled: false  # Disabled - won't be deployed
    description: "Automated TLS certificate management"
    manifestPath: "cert-manager.yaml"
```

## How It Works

### GitHub Actions (Automatic)
The workflow automatically reads `app-of-apps.yaml` and deploys only enabled applications:
```yaml
- name: Deploy Applications (based on app-of-apps.yaml)
  run: python3 scripts/apply-apps.py
```

### Local Deployment

**Option 1: Python script (recommended)**
```bash
./scripts/apply-apps.py
```

**Option 2: Bash script (requires yq)**
```bash
./scripts/apply-apps.sh
```

**Option 3: Manual**
```bash
# Apply only enabled apps
kubectl apply -f k8s-apps/argocd-apps/karpenter.yaml
kubectl apply -f k8s-apps/argocd-apps/cert-manager.yaml
```

## Adding New Applications

1.  **Create the ArgoCD Application manifest**
    ```bash
    # Create the manifest file
    vim k8s-apps/argocd-apps/my-app.yaml
    ```

2.  **Add entry to app-of-apps.yaml**
    ```yaml
    applications:
      my-app:
        enabled: true
        description: "My awesome application"
        manifestPath: "my-app.yaml"
    ```

3.  **Commit and push**
    ```bash
    git add k8s-apps/argocd-apps/
    git commit -m "Add my-app"
    git push
    ```

## Disabling Applications

Simply set `enabled: false` in `app-of-apps.yaml`:

```yaml
applications:
  karpenter:
    enabled: false  # This app will be skipped
    description: "..."
    manifestPath: "karpenter.yaml"
```

**Note:** This prevents new deployments. To remove an already-deployed app:
```bash
kubectl delete application karpenter -n argocd
```

## Benefits

**Centralized Control** - One file to manage all apps  
**Self-Documenting** - Descriptions explain what each app does  
**Version Controlled** - Changes tracked in Git  
**Environment-Specific** - Different configs for dev/staging/prod  
**Safe** - Can disable apps without deleting manifests

## Troubleshooting

### Script says "yq not installed"
The bash script requires `yq`. Either:
- Install yq: `brew install yq` (Mac) or see [yq docs](https://github.com/mikefarah/yq)
- Use Python script instead: `./scripts/apply-apps.py`

### Application not deploying
1. Check `app-of-apps.yaml` - is `enabled: true`?
2. Verify `manifestPath` points to correct file
3. Check manifest file exists in `k8s-apps/argocd-apps/`
4. View logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

### Want to see what would be deployed?
```bash
# Dry run
python3 scripts/apply-apps.py --dry-run  # (feature to be added)

# Or check manually
cat k8s-apps/argocd-apps/app-of-apps.yaml
```

## Migration from Old Setup

If you were manually applying all `.yaml` files:

**Before:**
```bash
kubectl apply -f k8s-apps/argocd-apps/*.yaml
```

**After:**
```bash
./scripts/apply-apps.py  # Respects app-of-apps.yaml configuration
```
