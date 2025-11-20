#!/bin/bash

# Configuration Script for EKS GitOps Automation
# This script replaces the GitHub username placeholder in all ArgoCD application files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}EKS GitOps Automation - Repository Configuration${NC}"
echo ""

# Get GitHub username
if [ -z "$GITHUB_USERNAME" ]; then
  echo -e "${YELLOW}Enter your GitHub username:${NC}"
  read -r GITHUB_USERNAME
fi

if [ -z "$GITHUB_USERNAME" ]; then
  echo -e "${RED}Error: GitHub username cannot be empty${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}Configuring ArgoCD applications for GitHub user: ${GITHUB_USERNAME}${NC}"
echo ""

# Directory containing ArgoCD application files
ARGOCD_APPS_DIR="$(dirname "$0")/../k8s-apps/argocd-apps"

# Files to update
FILES=(
  "$ARGOCD_APPS_DIR/karpenter.yaml"
  "$ARGOCD_APPS_DIR/cert-manager.yaml"
)

# Backup and replace
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "  Updating: $(basename "$file")"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Replace YOUR_USERNAME with actual username
    sed -i "s/YOUR_USERNAME/$GITHUB_USERNAME/g" "$file"
    
    echo -e "  ${GREEN}Updated $(basename "$file")${NC}"
  else
    echo -e "  ${YELLOW}File not found: $file${NC}"
  fi
done

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes in k8s-apps/argocd-apps/"
echo "  2. Commit and push to GitHub"
echo "  3. Deploy your cluster!"
echo ""
echo "To restore original files, run:"
echo "  cd k8s-apps/argocd-apps && mv *.bak original/"
