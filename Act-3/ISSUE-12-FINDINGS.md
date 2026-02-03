# Issue #12 - Root Cause Analysis Findings

**Issue:** [🚨 ArgoCD Deployment Failed: 2-broken-apps](https://github.com/DevExpGbb/agentic-platform-engineering/issues/12)  
**Date:** 2026-02-03  
**Analyzed By:** GitHub Copilot Agent

---

## 🔍 Root Cause Analysis Complete

I've completed a thorough analysis of the deployment failure for the `2-broken-apps` application. 

### 📋 Summary

The deployment is failing due to **TWO critical issues** in the source repository manifest (`apps/broken-aks-store-all-in-one.yaml`):

---

### ❌ Issue #1: Invalid API Version (Line 178)

**Location:** [`apps/broken-aks-store-all-in-one.yaml:178`](https://github.com/dcasati/argocd-notification-examples/blob/main/apps/broken-aks-store-all-in-one.yaml#L178)

**Current Code:**
```yaml
apiVersion: apps/v
kind: Deployment
metadata:
  name: order-service
```

**Problem:** The `apiVersion` is incomplete - it should be `apps/v1` not `apps/v`.

**Impact:**
- ❌ Kubernetes API server rejects the manifest
- ❌ ArgoCD sync fails with "synchronization tasks are not valid"  
- ❌ The `order-service` deployment cannot be created
- ❌ Cascading failure blocks entire application stack

**Fix:**
```yaml
apiVersion: apps/v1  # Changed from apps/v
```

---

### ❌ Issue #2: Typo in Docker Image Name (Line 475)

**Location:** [`apps/broken-aks-store-all-in-one.yaml:475`](https://github.com/dcasati/argocd-notification-examples/blob/main/apps/broken-aks-store-all-in-one.yaml#L475)

**Current Code:**
```yaml
- name: store-admin
  image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0
```

**Problem:** Typo in image name - `store-dmin` should be `store-admin`.

**Impact:**
- ❌ Container image pull fails with `ImagePullBackOff`
- ❌ Pod remains stuck in `Pending` state
- ❌ Deployment becomes degraded
- ❌ Health checks fail

**Fix:**
```yaml
image: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
```

---

## 🎯 Recommended Remediation

Since both issues exist in the **external source repository** (https://github.com/dcasati/argocd-notification-examples.git), you have three options:

### Option 1: Fork & Fix (Recommended for testing) ⭐

1. Fork the repository: https://github.com/dcasati/argocd-notification-examples
2. Fix both issues in your fork
3. Update the ArgoCD app to point to your fork temporarily:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/<your-fork>/argocd-notification-examples.git
       targetRevision: fixed-branch
   ```

### Option 2: Host Corrected Manifests Locally

1. Copy the corrected manifest to this repository under `manifests/aks-store/`
2. Update [`Act-3/argocd-test-app.yaml`](https://github.com/DevExpGbb/agentic-platform-engineering/blob/main/Act-3/argocd-test-app.yaml) to point to the local path

### Option 3: Use Kustomize Overlays (Advanced)

Create Kustomize patches to fix the remote manifest without forking.

---

## 📄 Full Documentation

I've created a comprehensive Root Cause Analysis document with detailed remediation steps, verification procedures, and impact analysis:

**📖 [View Full RCA Document](./RCA-2-broken-apps.md)**

---

## ✅ Next Steps

1. **Choose a remediation option** based on your requirements
2. **Implement the fixes** to the source manifests
3. **Sync the ArgoCD application**:
   ```bash
   argocd app sync 2-broken-apps
   ```
4. **Verify deployment**:
   ```bash
   kubectl get pods -n default
   argocd app get 2-broken-apps
   ```

---

## 📊 Impact Summary

| Issue | Location | Severity | Fix Required |
|-------|----------|----------|--------------|
| Invalid apiVersion | Line 178 | **Critical** | `apps/v` → `apps/v1` |
| Invalid image name | Line 475 | **High** | `store-dmin` → `store-admin` |

---

**Analysis Status:** ✅ Complete  
**Root Cause:** Identified (syntax errors in upstream repository)  
**Documentation:** [RCA-2-broken-apps.md](./RCA-2-broken-apps.md)  
**Ready for Remediation:** Yes

---

## 🔗 Related Links

- [Issue #12](https://github.com/DevExpGbb/agentic-platform-engineering/issues/12)
- [Source Repository](https://github.com/dcasati/argocd-notification-examples)
- [ArgoCD Application Definition](./argocd-test-app.yaml)
- [Full RCA Document](./RCA-2-broken-apps.md)
