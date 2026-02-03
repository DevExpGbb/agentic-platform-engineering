# Root Cause Analysis: ArgoCD Deployment Failure (2-broken-apps)

**Date:** 2026-02-03  
**Application:** `2-broken-apps`  
**Status:** Analyzed  
**Analyst:** GitHub Copilot Agent

---

## 🔍 Root Cause Analysis

I've investigated the ArgoCD deployment failure for the `2-broken-apps` application and identified **two critical issues** in the source repository that are causing the deployment to fail.

### Issue 1: Invalid API Version in Order Service Deployment ❌

**Location:** `apps/broken-aks-store-all-in-one.yaml` (line 178)

**Problem:**
```yaml
apiVersion: apps/v  # ❌ INVALID - Truncated API version
kind: Deployment
metadata:
  name: order-service
```

**Expected:**
```yaml
apiVersion: apps/v1  # ✅ CORRECT
kind: Deployment
metadata:
  name: order-service
```

**Impact:** This malformed API version prevents Kubernetes from validating and applying the Deployment resource, causing ArgoCD sync to fail with "one or more synchronization tasks are not valid."

**Root Cause:** This was introduced in commit `8cd04df` with the commit message "break apiVersion formatting in deployment YAML" - this appears to be an intentional breaking change for testing purposes.

---

### Issue 2: Invalid Container Image Name for Store Admin Deployment ❌

**Location:** `apps/broken-aks-store-all-in-one.yaml` (line 475)

**Problem:**
```yaml
image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0  # ❌ TYPO - "dmin" instead of "admin"
```

**Expected:**
```yaml
image: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0  # ✅ CORRECT
```

**Impact:** This will cause the `store-admin` deployment to fail with an image pull error since the image `store-dmin` doesn't exist in the registry.

---

## 🛠️ Remediation Recommendations

### Option 1: Fix the Source Repository (Recommended)
**If you own or have access to the source repository:**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dcasati/argocd-notification-examples.git
   cd argocd-notification-examples
   ```

2. **Fix the API version:**
   ```bash
   sed -i 's/apiVersion: apps\/v$/apiVersion: apps\/v1/' apps/broken-aks-store-all-in-one.yaml
   ```

3. **Fix the image name:**
   ```bash
   sed -i 's/store-dmin:2.1.0/store-admin:2.1.0/' apps/broken-aks-store-all-in-one.yaml
   ```

4. **Commit and push the changes:**
   ```bash
   git add apps/broken-aks-store-all-in-one.yaml
   git commit -m "Fix API version and image name in broken-aks-store-all-in-one.yaml"
   git push origin main
   ```

5. **Trigger ArgoCD sync:**
   ```bash
   argocd app sync 2-broken-apps
   ```

---

### Option 2: Use a Different Source or Fork
**If you don't have access to the source repository:**

1. **Fork the repository to your own GitHub account**

2. **Apply the fixes mentioned above to your fork**

3. **Update the ArgoCD application to point to your fork:**
   ```bash
   kubectl patch application 2-broken-apps -n argocd --type=merge -p '{"spec":{"source":{"repoURL":"https://github.com/YOUR-USERNAME/argocd-notification-examples.git"}}}'
   ```

---

### Option 3: Use Kustomize Overlay to Patch the Resources
**If you want to keep the original source but apply fixes:**

1. **Create a Kustomize overlay structure:**
   ```bash
   mkdir -p overlays/prod
   ```

2. **Create a `kustomization.yaml` file:**
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
     - https://github.com/dcasati/argocd-notification-examples.git//apps?ref=main
   
   patches:
     - target:
         kind: Deployment
         name: order-service
       patch: |-
         - op: replace
           path: /apiVersion
           value: apps/v1
     - target:
         kind: Deployment
         name: store-admin
       patch: |-
         - op: replace
           path: /spec/template/spec/containers/0/image
           value: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
   ```

3. **Update ArgoCD application to use the overlay:**
   Update `Act-3/argocd-test-app.yaml` to point to your overlay directory.

---

### Option 4: Switch to a Working Example Repository
**If this is just for testing/demonstration:**

Consider using the official AKS Store Demo repository which has working configurations:
```yaml
source:
  repoURL: https://github.com/Azure-Samples/aks-store-demo
  targetRevision: main
  path: aks-store-all-in-one.yaml
```

---

## 📋 Verification Steps

After applying any of the remediation options above:

1. **Check ArgoCD sync status:**
   ```bash
   argocd app get 2-broken-apps
   ```

2. **Verify all resources are healthy:**
   ```bash
   kubectl get pods -n default
   kubectl get deployments -n default
   ```

3. **Check for any events or errors:**
   ```bash
   kubectl get events -n default --sort-by='.lastTimestamp' | head -20
   ```

4. **Verify the store-admin deployment:**
   ```bash
   kubectl describe deployment store-admin -n default
   kubectl get pods -l app=store-admin -n default
   ```

---

## 📊 Summary

| Issue | Severity | Location | Fix Complexity |
|-------|----------|----------|----------------|
| Invalid API version (`apps/v`) | **Critical** | order-service Deployment | Low (1 character) |
| Invalid image name (`store-dmin`) | **High** | store-admin Deployment | Low (4 characters) |

Both issues are simple typos that prevent successful deployment. The quickest resolution is to fix the source YAML file if you have access, or fork the repository and apply the fixes there.

---

**Note:** Based on the commit message "break apiVersion formatting in deployment YAML," it appears these errors were intentionally introduced for testing ArgoCD notification functionality. If this is the case and you want to test failure scenarios, you may want to keep the broken state. However, if the goal is to have a working deployment, please apply one of the remediation options above.

---

## Investigation Details

**Source Repository:** https://github.com/dcasati/argocd-notification-examples.git  
**Failing Revision:** `8cd04df204028ff78613a69fdb630625864037c6`  
**Investigation Method:** Cloned and analyzed source repository YAML files  
**Tools Used:** git, grep, manual YAML inspection

**Timeline:**
- 2026-02-03T18:43:13Z - Deployment failure detected by ArgoCD
- 2026-02-03T21:54:00Z - Root cause analysis completed
