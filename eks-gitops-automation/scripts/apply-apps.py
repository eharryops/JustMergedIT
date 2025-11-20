#!/usr/bin/env python3
"""
Apply ArgoCD Applications Based on app-of-apps.yaml Configuration
This script reads app-of-apps.yaml and only applies enabled applications
"""

import yaml
import subprocess
import sys
from pathlib import Path

# Colors for terminal output
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def print_colored(color, message):
    print(f"{color}{message}{Colors.NC}")

def main():
    # Paths
    script_dir = Path(__file__).parent
    argocd_apps_dir = script_dir.parent / "k8s-apps" / "argocd-apps"
    apps_config = argocd_apps_dir / "app-of-apps.yaml"
    
    print_colored(Colors.BLUE, "Deploying ArgoCD Applications")
    print()
    
    # Check if app-of-apps.yaml exists
    if not apps_config.exists():
        print_colored(Colors.YELLOW, "app-of-apps.yaml not found, applying all applications")
        subprocess.run(["kubectl", "apply", "-f", str(argocd_apps_dir / "*.yaml")])
        return 0
    
    # Read app-of-apps.yaml
    try:
        with open(apps_config, 'r') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print_colored(Colors.RED, f"Error reading app-of-apps.yaml: {e}")
        return 1
    
    print("Reading configuration from app-of-apps.yaml...")
    print()
    
    # Get enabled applications
    applications = config.get('applications', {})
    applied_count = 0
    skipped_count = 0
    
    for app_name, app_config in applications.items():
        enabled = app_config.get('enabled', False)
        manifest_path = app_config.get('manifestPath')
        description = app_config.get('description', '')
        
        if not manifest_path:
            print_colored(Colors.YELLOW, f"{app_name}: No manifestPath specified, skipping")
            continue
        
        manifest_file = argocd_apps_dir / manifest_path
        
        if enabled:
            if manifest_file.exists():
                print_colored(Colors.GREEN, f"Applying: {app_name}")
                if description:
                    print(f"  {description}")
                
                try:
                    subprocess.run(
                        ["kubectl", "apply", "-f", str(manifest_file)],
                        check=True,
                        capture_output=True
                    )
                    applied_count += 1
                except subprocess.CalledProcessError as e:
                    print_colored(Colors.RED, f"  Failed to apply {app_name}")
                    print(f"  Error: {e.stderr.decode()}")
            else:
                print_colored(Colors.YELLOW, f"{app_name}: Manifest not found at {manifest_path}")
        else:
            print_colored(Colors.YELLOW, f"Skipping: {app_name} (disabled)")
            skipped_count += 1
    
    print()
    print_colored(Colors.GREEN, f"Deployment complete: {applied_count} applied, {skipped_count} skipped")
    print()
    print("To view deployed applications:")
    print("  kubectl get applications -n argocd")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
