# Root Cause Analysis: ArgoCD Deployment Failure (2-broken-apps)

**Investigation Date:** 2026-02-03  
**Issue:** #12 - 🚨 ArgoCD Deployment Failed: 2-broken-apps  
**Status:** Root Cause Identified

---

## 🔍 Root Cause Analysis

I've investigated the ArgoCD deployment failure for the `2-broken-apps` application and identified the root cause.

### Summary
The deployment is failing due to an **invalid Kubernetes manifest** in the source repository. Specifically, there is a malformed `apiVersion` field in the `order-service` Deployment manifest.

### Root Cause Details

**Location:** `apps/broken-aks-store-all-in-one.yaml` (lines 178-179)

**Issue:** The `apiVersion` field is incomplete:
```yaml
apiVersion: apps/v    # ❌ INVALID - incomplete version
kind: Deployment
metadata:
  name: order-service
```

**Expected:**
```yaml
apiVersion: apps/v1   # ✅ CORRECT
kind: Deployment
metadata:
  name: order-service
```

### Technical Analysis

1. **Repository:** https://github.com/dcasati/argocd-notification-examples.git
2. **Broken Commit:** `8cd04df204028ff78613a69fdb630625864037c6`
3. **Commit Message:** "break apiVersion formatting in deployment YAML"
4. **Affected Resource:** `order-service` Deployment in `apps/broken-aks-store-all-in-one.yaml`

The error message "one or more synchronization tasks are not valid" is ArgoCD's response to encountering an invalid Kubernetes manifest that cannot be parsed or validated against the Kubernetes API.

### Impact

- **Health Status:** Degraded (as reported)
- **Sync Status:** OutOfSync (as reported)
- **Failed Resource:** order-service Deployment
- **Retry Behavior:** ArgoCD attempted to sync 2 times before giving up (as configured in the retry policy)

---

## 📋 Remediation Recommendations

### Option 1: Fix the Source Repository (Recommended)
This is the proper long-term fix if you control the source repository:

```bash
# 1. Clone the source repository
git clone https://github.com/dcasati/argocd-notification-examples.git
cd argocd-notification-examples

# 2. Edit the broken manifest
# Change line 178 from "apiVersion: apps/v" to "apiVersion: apps/v1"
sed -i 's/apiVersion: apps\/v$/apiVersion: apps\/v1/' apps/broken-aks-store-all-in-one.yaml

# 3. Commit and push the fix
git add apps/broken-aks-store-all-in-one.yaml
git commit -m "Fix: Complete apiVersion for order-service Deployment"
git push origin main

# 4. Trigger ArgoCD sync
argocd app sync 2-broken-apps
```

### Option 2: Use a Different Revision
Point the ArgoCD Application to a working commit (if one exists before the breaking change):

```bash
# Find a working commit
git log --oneline apps/broken-aks-store-all-in-one.yaml

# Update the ArgoCD Application to use that revision
argocd app set 2-broken-apps --revision <working-commit-sha>
argocd app sync 2-broken-apps
```

### Option 3: Use a Different Source Repository
If this repository is intentionally broken for testing, update the ArgoCD Application manifest to point to a working repository:

```bash
# Edit Act-3/argocd-test-app.yaml
# Change spec.source.repoURL to a valid repository
# For example: https://github.com/Azure-Samples/aks-store-demo.git
# Change spec.source.path to a valid path
# For example: aks-store-all-in-one.yaml
```

### Option 4: Delete the Application (If Testing)
If this was intentionally created to test the ArgoCD notification system and is no longer needed:

```bash
# Delete the application from ArgoCD
argocd app delete 2-broken-apps

# Or delete the manifest file
kubectl delete -f Act-3/argocd-test-app.yaml
```

---

## 🔐 Additional Observations

Based on the repository structure and commit message, this appears to be an **intentional test case** to validate the ArgoCD notification system. The repository is named "argocd-notification-examples" and the commit explicitly states it's breaking the YAML.

**If this is a test:**
- ✅ The notification system is working correctly
- ✅ GitHub Actions workflow successfully created this issue
- ✅ The error detection and reporting mechanism is functioning as designed

**If this is not a test:**
- Follow Option 1 above to fix the source repository
- Verify the fix by running: `kubectl apply --dry-run=server -f apps/broken-aks-store-all-in-one.yaml`

---

## 📊 Verification Steps

After applying any fix, verify the deployment:

```bash
# 1. Check application status
argocd app get 2-broken-apps

# 2. Watch for sync completion
argocd app wait 2-broken-apps --health

# 3. Verify pods are running
kubectl get pods -n default -l app=order-service

# 4. Check deployment status
kubectl describe deployment order-service -n default
```

---

## Investigation Methodology

1. **Examined ArgoCD Application Manifest**
   - Located at: `Act-3/argocd-test-app.yaml`
   - Identified source repository and path

2. **Cloned Source Repository**
   - Repository: https://github.com/dcasati/argocd-notification-examples.git
   - Analyzed commit history and current state

3. **Identified Broken Manifest**
   - File: `apps/broken-aks-store-all-in-one.yaml`
   - Line 178: Malformed `apiVersion: apps/v` (missing the `1`)

4. **Confirmed Root Cause**
   - The incomplete apiVersion prevents Kubernetes from parsing the manifest
   - ArgoCD cannot validate or apply the resource
   - Results in "synchronization tasks are not valid" error

---

**Note:** This root cause analysis was performed by examining the source repository at revision `8cd04df204028ff78613a69fdb630625864037c6` and identifying the malformed `apiVersion` field in the order-service Deployment manifest.
