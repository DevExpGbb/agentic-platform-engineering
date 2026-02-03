# ArgoCD Deployment Failure Analysis: 2-broken-apps

## 🔍 Root Cause Analysis

I've investigated the ArgoCD deployment failure for the `2-broken-apps` application and identified **two critical issues** in the source repository that are causing the synchronization failures.

### Issues Found

#### 1. ❌ Invalid Kubernetes API Version (Line 178)
**Location:** `apps/broken-aks-store-all-in-one.yaml:178`

```yaml
apiVersion: apps/v    # ❌ INVALID
kind: Deployment
metadata:
  name: order-service
```

**Problem:** The `apiVersion` field is incomplete. It should be `apps/v1`, not `apps/v`.

**Impact:** This causes Kubernetes to reject the manifest during validation, preventing the `order-service` Deployment from being created.

---

#### 2. ❌ Typo in Container Image Name (Line 475)
**Location:** `apps/broken-aks-store-all-in-one.yaml:475`

```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0  # ❌ TYPO: "store-dmin"
```

**Problem:** The image name has a typo: `store-dmin` instead of `store-admin` (missing 'a').

**Impact:** The container image pull will fail with `ImagePullBackOff` error because the image `ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0` does not exist in the registry.

---

### 🔧 Remediation Recommendations

Since the source repository (`https://github.com/dcasati/argocd-notification-examples.git`) is external and appears to be intentionally broken for demonstration purposes, here are the recommended remediation steps:

#### Option 1: Fork and Fix the Repository (Recommended)
1. **Fork the repository** to your organization or personal GitHub account
2. **Fix the two issues** in the forked repository:
   ```bash
   # Clone the forked repository
   git clone https://github.com/YOUR-ORG/argocd-notification-examples.git
   cd argocd-notification-examples
   
   # Fix line 178: Change "apps/v" to "apps/v1"
   sed -i '178s/apiVersion: apps\/v$/apiVersion: apps\/v1/' apps/broken-aks-store-all-in-one.yaml
   
   # Fix line 475: Change "store-dmin" to "store-admin"
   sed -i '475s/store-dmin/store-admin/' apps/broken-aks-store-all-in-one.yaml
   
   # Commit and push the changes
   git add apps/broken-aks-store-all-in-one.yaml
   git commit -m "Fix: Correct apiVersion and image name typos"
   git push origin main
   ```

3. **Update the ArgoCD Application manifest** (`Act-3/argocd-test-app.yaml`) to point to your forked repository:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR-ORG/argocd-notification-examples.git  # Update this
       targetRevision: main
       path: apps
   ```

#### Option 2: Use a Local/Internal Repository
1. Create a new directory in this repository (e.g., `Act-3/apps/`)
2. Copy and fix the broken manifest file
3. Update the ArgoCD Application to use a local path instead of the external repository

#### Option 3: Keep as a Test Case (If Intentional)
If this is meant to remain a broken application for testing ArgoCD notifications:
1. Document that this is an intentional failure test case
2. Add a label or annotation to the issue indicating this is expected behavior
3. Consider renaming the application to make it clear it's for testing (e.g., `test-broken-apps`)

---

### 📝 Verification Steps

After applying the fixes, verify the deployment:

```bash
# 1. Check ArgoCD sync status
argocd app sync 2-broken-apps
argocd app get 2-broken-apps

# 2. Verify all pods are running
kubectl get pods -n default

# 3. Check for any remaining issues
kubectl get events -n default --sort-by='.lastTimestamp' | grep -i error

# 4. Verify the deployments are healthy
kubectl get deployments -n default
kubectl get statefulsets -n default
```

---

### 📊 Summary

| Issue | Location | Severity | Fix |
|-------|----------|----------|-----|
| Invalid apiVersion | Line 178 | 🔴 Critical | Change `apps/v` to `apps/v1` |
| Image name typo | Line 475 | 🔴 Critical | Change `store-dmin` to `store-admin` |

Both issues must be fixed for the application to deploy successfully. The recommended approach is to fork the repository, apply the fixes, and update the ArgoCD application to use the corrected repository.

---

## Issue Comment

**Note:** This analysis was prepared to be posted as a comment on GitHub Issue #12. Due to permission limitations in the automated environment, this document was created instead. Please manually copy this content to the issue thread, or use the following command:

```bash
gh issue comment 12 --body-file ARGOCD_FAILURE_ANALYSIS.md
```
