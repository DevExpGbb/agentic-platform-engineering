# Root Cause Analysis: ArgoCD Deployment Failure (2-broken-apps)

**Investigation Date:** 2026-02-03  
**Application:** `2-broken-apps`  
**Status:** Degraded / OutOfSync  
**Related Issue:** #12

## 🔍 Root Cause Analysis

I've investigated the ArgoCD deployment failure for the `2-broken-apps` application and identified **two critical issues** in the source repository's Kubernetes manifest file.

### Issue 1: Invalid apiVersion ❌

**Location:** Line 178 in `apps/broken-aks-store-all-in-one.yaml` from repository `https://github.com/dcasati/argocd-notification-examples.git`

```yaml
apiVersion: apps/v
kind: Deployment
metadata:
  name: order-service
```

**Problem:** The `apiVersion` field is incomplete. It should be `apps/v1` but is only `apps/v`.

**Impact:** This causes ArgoCD sync to fail because Kubernetes cannot recognize this as a valid resource definition. The error message "one or more synchronization tasks are not valid" is a direct result of this malformed apiVersion.

---

### Issue 2: Incorrect Container Image Name ❌

**Location:** Line 475 in `apps/broken-aks-store-all-in-one.yaml`

```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0
```

**Problem:** The image name has a typo: `store-dmin` should be `store-admin`.

**Impact:** Even if the manifest syncs successfully after fixing Issue 1, this pod will fail to start because the image `store-dmin:2.1.0` doesn't exist in the container registry. Only `store-admin:2.1.0` exists.

---

## 🔧 Remediation Recommendations

### Option 1: Fix the Source Repository (Recommended) ⭐

Since the application is pointing to an external repository (`https://github.com/dcasati/argocd-notification-examples.git`), the best solution is to fix the issues at the source:

1. **Contact the repository owner** (@dcasati) or submit a pull request to fix:
   - **Line 178:** Change `apiVersion: apps/v` to `apiVersion: apps/v1`
   - **Line 475:** Change `ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0` to `ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0`

2. **Wait for ArgoCD auto-sync** (configured with `automated: true`) or manually trigger sync:
   ```bash
   argocd app sync 2-broken-apps
   ```

3. **Verify the deployment** using the verification steps below.

**Advantages:**
- Fixes the root cause
- Maintains GitOps principles
- Benefits other users of the repository

---

### Option 2: Fork and Fix 🍴

If you need immediate resolution and cannot wait for the upstream fix:

1. **Fork the repository** to your own GitHub account or organization:
   ```bash
   # Via GitHub UI or:
   gh repo fork dcasati/argocd-notification-examples --clone=false
   ```

2. **Clone your fork and fix the issues:**
   ```bash
   git clone https://github.com/YOUR-ORG/argocd-notification-examples.git
   cd argocd-notification-examples
   
   # Fix Issue 1
   sed -i 's/apiVersion: apps\/v$/apiVersion: apps\/v1/' apps/broken-aks-store-all-in-one.yaml
   
   # Fix Issue 2
   sed -i 's/store-dmin:2.1.0/store-admin:2.1.0/' apps/broken-aks-store-all-in-one.yaml
   
   git commit -am "Fix apiVersion and image name typos"
   git push
   ```

3. **Update the ArgoCD Application** spec in `Act-3/argocd-test-app.yaml`:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR-ORG/argocd-notification-examples.git
       targetRevision: main
       path: apps
   ```

4. **Apply the updated ArgoCD Application:**
   ```bash
   kubectl apply -f Act-3/argocd-test-app.yaml
   ```

**Advantages:**
- Immediate resolution
- Full control over the manifests
- Can be used until upstream is fixed

---

### Option 3: Local Patch (Not Recommended) ⚠️

Apply the resources with corrections directly to the cluster:

```bash
# Download and fix the manifest
curl -o /tmp/fixed-app.yaml https://raw.githubusercontent.com/dcasati/argocd-notification-examples/main/apps/broken-aks-store-all-in-one.yaml

# Edit /tmp/fixed-app.yaml to fix both issues, then apply:
kubectl apply -f /tmp/fixed-app.yaml -n default
```

**Disadvantages:**
- Creates drift from GitOps source
- ArgoCD will constantly try to sync back to the broken state
- Not a sustainable solution

---

## ✅ Verification Steps

After applying the fix (via Option 1 or 2):

### 1. Check ArgoCD Application Status

```bash
# Check overall application health
argocd app get 2-broken-apps

# Expected output should show:
# - Health Status: Healthy
# - Sync Status: Synced
```

### 2. Verify All Pods Are Running

```bash
# Check all pods in the namespace
kubectl get pods -n default

# Check specific deployments
kubectl get deployment order-service -n default
kubectl get deployment store-admin -n default

# Expected: All deployments should show READY 1/1
```

### 3. Verify Deployments in Detail

```bash
# Check order-service deployment
kubectl describe deployment order-service -n default

# Check store-admin deployment  
kubectl describe deployment store-admin -n default

# Verify the image name is correct
kubectl get deployment store-admin -n default -o jsonpath='{.spec.template.spec.containers[0].image}'
# Expected: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
```

### 4. Check Pod Logs (if issues persist)

```bash
# Check order-service logs
kubectl logs deployment/order-service -n default --tail=50

# Check store-admin logs
kubectl logs deployment/store-admin -n default --tail=50
```

### 5. Monitor ArgoCD Sync

```bash
# Watch the sync progress
argocd app sync 2-broken-apps --watch

# Check recent sync history
argocd app history 2-broken-apps
```

---

## 📋 Summary

The deployment failure is caused by **two distinct issues** in the external repository's manifest file:

| Issue | Location | Current Value | Expected Value |
|-------|----------|---------------|----------------|
| **Invalid apiVersion** | Line 178 | `apiVersion: apps/v` | `apiVersion: apps/v1` |
| **Typo in Image Name** | Line 475 | `store-dmin:2.1.0` | `store-admin:2.1.0` |

### Recommended Action

**Primary:** Contact the repository owner (@dcasati) or submit a PR to https://github.com/dcasati/argocd-notification-examples.git fixing both issues, then re-sync the ArgoCD application.

**Alternative:** Fork the repository, fix the issues, and update your ArgoCD application to point to your fork for immediate resolution.

---

## 🔗 References

- **Source Repository:** https://github.com/dcasati/argocd-notification-examples.git
- **Problematic File:** `apps/broken-aks-store-all-in-one.yaml`
- **ArgoCD Application Config:** `Act-3/argocd-test-app.yaml`
- **Related Issue:** #12
- **Application Name:** `2-broken-apps`
- **Namespace:** `default`
- **Cluster:** `aks-eastus2`

---

*Analysis completed by: Copilot Agent*  
*Date: 2026-02-03*
