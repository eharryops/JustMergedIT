#!/bin/bash

# Apply ArgoCD Applications Based on app-of-apps.yaml Configuration
# This script reads app-of-apps.yaml and only applies enabled applications

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_APPS_DIR="$SCRIPT_DIR/../k8s-apps/argocd-apps"
APPS_CONFIG="$ARGOCD_APPS_DIR/app-of-apps.yaml"

echo -e "${BLUE}Deploying ArgoCD Applications${NC}"
echo ""

# Check if app-of-apps.yaml exists
if [ ! -f "$APPS_CONFIG" ]; then
  echo -e "${YELLOW}app-of-apps.yaml not found, applying all applications${NC}"
  kubectl apply -f "$ARGOCD_APPS_DIR"/*.yaml
  exit 0
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo -e "${YELLOW}yq not installed, applying all applications${NC}"
  echo "   Install yq for selective deployment: https://github.com/mikefarah/yq"
  kubectl apply -f "$ARGOCD_APPS_DIR"/*.yaml
  exit 0
fi

echo "Reading configuration from app-of-apps.yaml..."
echo ""

# Parse app-of-apps.yaml and apply enabled applications
yq eval '.applications | to_entries | .[] | select(.value.enabled == true) | .value.manifestPath' "$APPS_CONFIG" | while read -r manifest; do
  manifest_file="$ARGOCD_APPS_DIR/$manifest"
  
  if [ -f "$manifest_file" ]; then
    app_name=$(yq eval '.metadata.name' "$manifest_file")
    echo -e "${GREEN}Applying: $app_name (from $manifest)${NC}"
    kubectl apply -f "$manifest_file"
  else
    echo -e "${YELLOW}Manifest not found: $manifest${NC}"
  fi
done

echo ""
echo -e "${GREEN}Application deployment complete${NC}"
echo ""
echo "To view deployed applications:"
echo "  kubectl get applications -n argocd"
