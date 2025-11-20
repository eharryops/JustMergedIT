#!/bin/bash

## Custom script to retrieve the initial admin password for ArgoCD

echo "Getting ArgoCD initial admin password..."
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo

