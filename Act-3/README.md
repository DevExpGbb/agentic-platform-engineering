# Act 3: ArgoCD Deployment Failure Investigation

This directory contains the investigation results for the ArgoCD deployment failure of the `2-broken-apps` application.

## Quick Links

- 📊 **[Investigation Summary](INVESTIGATION_SUMMARY.md)** - Executive summary of findings
- 🔍 **[Root Cause Analysis](ROOT_CAUSE_ANALYSIS.md)** - Detailed technical analysis with remediation options
- 📝 **[How to Post RCA](HOW_TO_POST_RCA.md)** - Instructions for posting the analysis to GitHub issue #12

## Investigation Results

### Root Cause
Invalid Kubernetes manifest with incomplete `apiVersion` field in the source repository.

- **Location:** `apps/broken-aks-store-all-in-one.yaml` (line 178)
- **Issue:** `apiVersion: apps/v` (should be `apiVersion: apps/v1`)
- **Repository:** https://github.com/dcasati/argocd-notification-examples.git
- **Revision:** `8cd04df204028ff78613a69fdb630625864037c6`

### Conclusion
This appears to be an **intentional test case** to validate the ArgoCD notification system:
- ✅ The notification system detected the failure
- ✅ GitHub issue #12 was automatically created
- ✅ All error details were properly captured and reported

## Files in This Directory

| File | Description |
|------|-------------|
| `INVESTIGATION_SUMMARY.md` | Executive summary of the investigation |
| `ROOT_CAUSE_ANALYSIS.md` | Complete technical analysis with 4 remediation options |
| `HOW_TO_POST_RCA.md` | Instructions for posting analysis to GitHub issue |
| `post-rca-to-issue.sh` | Bash script for automated posting (requires GitHub token) |
| `argocd-test-app.yaml` | ArgoCD Application manifest (the one causing the issue) |

## Related Files

| File | Description |
|------|-------------|
| `../.github/workflows/post-rca-comment.yml` | GitHub Actions workflow for posting RCA to issue |
| `../.github/workflows/argocd-deployment-failure.yml` | Workflow that creates issues on ArgoCD failures |
| `../.github/argocd/argocd-notifications-config.yaml` | ArgoCD notification configuration |

## Remediation Options

The `ROOT_CAUSE_ANALYSIS.md` provides four options:

1. **Fix the source repository** (recommended if not a test)
2. **Use a different revision** (rollback to working commit)
3. **Use a different source repository** (point to valid repo)
4. **Delete the application** (if testing is complete)

## How to Use These Files

### To Post the Analysis to GitHub Issue #12

Choose one of these methods:

```bash
# Option 1: Using GitHub CLI
gh issue comment 12 --body-file ROOT_CAUSE_ANALYSIS.md

# Option 2: Using the bash script (requires GITHUB_TOKEN)
export GITHUB_TOKEN="your_token_here"
./post-rca-to-issue.sh 12

# Option 3: Manual copy/paste
# Open ROOT_CAUSE_ANALYSIS.md and copy content to GitHub issue #12
```

### To Fix the Issue

If this is not a test and needs to be fixed:

```bash
# Clone the source repository
git clone https://github.com/dcasati/argocd-notification-examples.git
cd argocd-notification-examples

# Fix the apiVersion
sed -i 's/apiVersion: apps\/v$/apiVersion: apps\/v1/' apps/broken-aks-store-all-in-one.yaml

# Commit and push
git add apps/broken-aks-store-all-in-one.yaml
git commit -m "Fix: Complete apiVersion for order-service Deployment"
git push origin main

# Trigger ArgoCD sync
argocd app sync 2-broken-apps
```

## Background: ArgoCD Notifications

This investigation demonstrates the ArgoCD notification system working correctly:

```
ArgoCD detects failure
    ↓
ArgoCD Notifications sends webhook
    ↓
GitHub repository_dispatch
    ↓
GitHub Actions creates issue
    ↓
GitHub Copilot investigates
    ↓
Root cause identified and documented
```

## Related Issues

- GitHub Issue #12: 🚨 ArgoCD Deployment Failed: 2-broken-apps
- GitHub Issue #11: 🚨 ArgoCD Deployment Failed: 2-broken-apps (duplicate)

---

**Investigation completed:** 2026-02-03  
**Investigated by:** GitHub Copilot Agent
