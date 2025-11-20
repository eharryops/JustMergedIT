# GitHub Repository Configuration

## Using Repository Variables (Recommended)

Instead of hardcoding your GitHub username, you can set it as a **repository variable** that the workflow will use automatically.

### Setup Steps:

1. **Go to Repository Settings**
   ```
   Your Repo → Settings → Secrets and variables → Actions → Variables tab
   ```

2. **Add Repository Variables** (Click "New repository variable")
   
   **Option A: Let it auto-detect (No setup needed!)**
   - The workflow automatically uses `github.repository_owner`
   - Works out of the box for anyone who forks the repo
   
   **Option B: Override with custom values**
   - Variable name: `GITHUB_USERNAME`
   - Value: `your-github-username`
   
   - Variable name: `REPO_NAME` (optional)
   - Value: `JustMergedIT`

### How It Works:

The workflow uses this logic:
```yaml
GITHUB_USER="${{ vars.GITHUB_USERNAME || github.repository_owner }}"
REPO_NAME="${{ vars.REPO_NAME || github.event.repository.name }}"
```

**Translation:**
- If `GITHUB_USERNAME` variable exists → use it
- Otherwise → auto-detect from repository owner
- Same for `REPO_NAME`

### Benefits:

- **No hardcoding** - Values stay in repo settings  
- **Fork-friendly** - Auto-detects for anyone who forks  
- **Override capability** - Can set custom values if needed  
- **Secure** - Variables are scoped to the repository  

### For Local Development:

Use the configuration script:
```bash
./scripts/configure-repo.sh
```

Or set environment variable:
```bash
export GITHUB_USERNAME=your-username
./scripts/configure-repo.sh
```

## Summary

**You don't need to do anything!** The workflow auto-detects your GitHub username. But if you want to override it, you can set the `GITHUB_USERNAME` repository variable.
