#!/bin/bash
# Script to post root cause analysis comment to GitHub issue #12
# Usage: ./scripts/post-analysis-to-issue.sh

set -e

ISSUE_NUMBER=12
REPO="DevExpGbb/agentic-platform-engineering"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub."
    echo "Please run: gh auth login"
    exit 1
fi

echo "📝 Posting root cause analysis comment to issue #$ISSUE_NUMBER..."

COMMENT=$(cat << 'EOF'
## 🔍 Root Cause Analysis

I've investigated the ArgoCD deployment failure for the `2-broken-apps` application and identified **two critical issues** in the source repository's Kubernetes manifest file.

### Issue 1: Invalid apiVersion ❌

**Location:** Line 178 in `apps/broken-aks-store-all-in-one.yaml`

```yaml
apiVersion: apps/v
kind: Deployment
metadata:
  name: order-service
```

**Problem:** The `apiVersion` field is incomplete. It should be `apps/v1` but is only `apps/v`.

**Impact:** This causes ArgoCD sync to fail because Kubernetes cannot recognize this as a valid resource definition.

---

### Issue 2: Incorrect Container Image Name ❌

**Location:** Line 475 in `apps/broken-aks-store-all-in-one.yaml`

```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0
```

**Problem:** The image name has a typo: `store-dmin` should be `store-admin`.

**Impact:** Even if the manifest syncs successfully, this pod will fail to start because the image doesn't exist in the container registry.

---

## 🔧 Remediation Recommendations

### Option 1: Fix the Source Repository (Recommended)

Since the application is pointing to an external repository (`https://github.com/dcasati/argocd-notification-examples.git`), the best solution is to fix the issues at the source:

1. **Contact the repository owner** (@dcasati) or submit a pull request to fix:
   - Line 178: Change `apiVersion: apps/v` to `apiVersion: apps/v1`
   - Line 475: Change `store-dmin` to `store-admin`

2. **Wait for ArgoCD auto-sync** (or manually trigger sync):
   ```bash
   argocd app sync 2-broken-apps
   ```

### Option 2: Fork and Fix

If you need immediate resolution:

1. **Fork the repository** to your own GitHub account or organization
2. **Fix the two issues** mentioned above
3. **Update the ArgoCD Application** spec in `Act-3/argocd-test-app.yaml`:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR-ORG/argocd-notification-examples.git
       targetRevision: main
       path: apps
   ```

### Option 3: Local Patch (Not Recommended)

Apply the resources with corrections directly to the cluster, but this will cause drift from the GitOps source.

---

## ✅ Verification Steps

After applying the fix:

1. **Check ArgoCD application status:**
   ```bash
   argocd app get 2-broken-apps
   ```

2. **Verify all pods are running:**
   ```bash
   kubectl get pods -n default
   kubectl get deployment order-service -n default
   kubectl get deployment store-admin -n default
   ```

3. **Check pod status and logs:**
   ```bash
   kubectl describe deployment order-service -n default
   kubectl describe deployment store-admin -n default
   kubectl logs deployment/store-admin -n default
   ```

---

## 📋 Summary

The deployment failure is caused by:
1. ✗ Incomplete `apiVersion: apps/v` (should be `apps/v1`) - **Line 178**
2. ✗ Typo in image name `store-dmin` (should be `store-admin`) - **Line 475**

**Recommended Action:** Contact the repository owner or submit a PR to fix these issues in the source repository, then re-sync the ArgoCD application.

---

*For detailed analysis, see [ARGOCD_FAILURE_ANALYSIS.md](https://github.com/DevExpGbb/agentic-platform-engineering/blob/main/ARGOCD_FAILURE_ANALYSIS.md)*
EOF
)

# Post the comment
gh issue comment $ISSUE_NUMBER --repo $REPO --body "$COMMENT"

echo "✅ Comment posted successfully!"
echo "🔗 View at: https://github.com/$REPO/issues/$ISSUE_NUMBER"
