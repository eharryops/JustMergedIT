#!/bin/bash

# Cluster Limit Check Script
# Enforces a maximum of 2 EKS clusters in the AWS account
# Usage: ./check-cluster-limit.sh [TARGET_CLUSTER_NAME]

set -e

MAX_CLUSTERS=2
AWS_REGION="${AWS_REGION:-us-east-1}"
TARGET_CLUSTER="${1:-}"

echo "Checking EKS cluster limit..."

# Get list of existing clusters
EXISTING_CLUSTERS=$(aws eks list-clusters --region "$AWS_REGION" --query 'clusters' --output text)

# Check if target cluster already exists
if [ -n "$TARGET_CLUSTER" ]; then
  # Check if TARGET_CLUSTER is in EXISTING_CLUSTERS (handling tab-separated output)
  if echo "$EXISTING_CLUSTERS" | tr '\t' '\n' | grep -q -w "$TARGET_CLUSTER"; then
    echo "Target cluster '$TARGET_CLUSTER' already exists. Skipping limit check."
    exit 0
  fi
fi

# Get current cluster count
CLUSTER_COUNT=$(aws eks list-clusters --region "$AWS_REGION" --query 'clusters | length(@)' --output text)

echo "Current cluster count: $CLUSTER_COUNT/$MAX_CLUSTERS"

# List existing clusters
if [ "$CLUSTER_COUNT" -gt 0 ]; then
  echo ""
  echo "Existing clusters:"
  aws eks list-clusters --region "$AWS_REGION" --output table
fi

# Check if limit is reached
if [ "$CLUSTER_COUNT" -ge "$MAX_CLUSTERS" ]; then
  echo ""
  echo "Error: Maximum cluster limit ($MAX_CLUSTERS) reached."
  echo "   Current clusters: $CLUSTER_COUNT"
  echo ""
  echo "To proceed, you must either:"
  echo "  1. Delete an existing cluster: aws eks delete-cluster --name <cluster-name> --region $AWS_REGION"
  echo "  2. Use an existing cluster name to update it"
  echo ""
  exit 1
fi

echo "Cluster limit check passed - you can create a new cluster"
exit 0
