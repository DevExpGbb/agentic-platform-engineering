# Root Cause Analysis: 2-broken-apps ArgoCD Deployment Failure

**Date:** 2026-02-03  
**Application:** `2-broken-apps`  
**Status:** ❌ Deployment Failed  
**Analyzed By:** GitHub Copilot Agent

---

## 🔍 Executive Summary

The ArgoCD application `2-broken-apps` is failing to deploy due to **TWO critical issues** in the source repository manifest file (`apps/broken-aks-store-all-in-one.yaml`):

1. **Invalid API Version** (Line 178) - Critical syntax error
2. **Invalid Docker Image Name** (Line 475) - Typo in image name

Both issues originate from the upstream source repository (https://github.com/dcasati/argocd-notification-examples.git) and require fixes at the source.

---

## 🕐 Timeline

- **Initial Detection:** ArgoCD sync failure detected
- **Investigation Started:** Manual review of manifest file
- **Root Cause Identified:** Two syntax/configuration errors found (lines 178, 475)
- **RCA Documented:** 2026-02-03
- **Status:** Awaiting remediation decision

---

## 🐛 Issue Details

### Issue #1: Invalid API Version (Line 178) ❌

**Location:** `apps/broken-aks-store-all-in-one.yaml:178`

**Current Code:**
```yaml
apiVersion: apps/v
kind: Deployment
metadata:
  name: order-service
```

**Problem:**
The `apiVersion` field is incomplete. It reads `apps/v` when it should be `apps/v1`.

**Impact:**
- Kubernetes API server rejects the manifest immediately
- ArgoCD reports: "one or more synchronization tasks are not valid"
- The `order-service` Deployment cannot be created
- Cascading failure blocks entire application stack

**Fix Required:**
```yaml
apiVersion: apps/v1  # Changed from apps/v
kind: Deployment
metadata:
  name: order-service
```

---

### Issue #2: Invalid Docker Image Name (Line 475) ❌

**Location:** `apps/broken-aks-store-all-in-one.yaml:475`

**Current Code:**
```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0
```

**Problem:**
The image name contains a typo: `store-dmin` instead of `store-admin`.

**Impact:**
- Container image pull fails with `ImagePullBackOff`
- Pod remains in `Pending` state indefinitely
- Deployment becomes degraded
- Application health check fails

**Fix Required:**
```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0  # Fixed typo
```

---

## 🎯 Remediation Options

Since these issues exist in an **external source repository**, there are three approaches to fix them:

### Option 1: Fix the Source Repository (Recommended) ⭐

**Best for:** Collaborative/Open Source scenarios

1. Fork https://github.com/dcasati/argocd-notification-examples
2. Create a new branch (e.g., `fix/manifest-errors`)
3. Fix both issues:
   - Line 178: `apps/v` → `apps/v1`
   - Line 475: `store-dmin` → `store-admin`
4. Submit a Pull Request to the upstream repository
5. Wait for merge or use your fork temporarily

**ArgoCD Update (temporary):**
```yaml
spec:
  source:
    repoURL: https://github.com/<your-fork>/argocd-notification-examples.git
    targetRevision: fix/manifest-errors
    path: apps
```

---

### Option 2: Host Corrected Manifests Locally

**Best for:** Quick fix/Internal control

1. Copy the corrected manifest to this repository:
   ```bash
   mkdir -p manifests/aks-store
   # Copy and fix the manifest
   ```

2. Update ArgoCD Application (`Act-3/argocd-test-app.yaml`):
   ```yaml
   spec:
     source:
       repoURL: https://github.com/DevExpGbb/agentic-platform-engineering.git
       targetRevision: main
       path: manifests/aks-store
   ```

3. Apply the updated ArgoCD Application:
   ```bash
   kubectl apply -f Act-3/argocd-test-app.yaml
   ```

---

### Option 3: Use Kustomize Overlays

**Best for:** Advanced patching without forking

1. Create a Kustomize overlay structure:
   ```
   manifests/aks-store/
   ├── kustomization.yaml
   └── patches/
       ├── order-service-apiversion.yaml
       └── store-admin-image.yaml
   ```

2. Configure Kustomize to patch the remote manifest:
   ```yaml
   # kustomization.yaml
   resources:
     - https://raw.githubusercontent.com/dcasati/argocd-notification-examples/main/apps/broken-aks-store-all-in-one.yaml
   
   patches:
     - path: patches/order-service-apiversion.yaml
     - path: patches/store-admin-image.yaml
   ```

3. Update ArgoCD to use Kustomize:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/DevExpGbb/agentic-platform-engineering.git
       targetRevision: main
       path: manifests/aks-store
       kustomize: {}
   ```

---

## 🧪 Verification Steps

After applying the fix:

### 1. Validate Syntax
```bash
kubectl apply --dry-run=client -f apps/broken-aks-store-all-in-one.yaml
```

### 2. Verify Image Availability
```bash
docker pull ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
```

### 3. Sync ArgoCD Application
```bash
argocd app sync 2-broken-apps
```

### 4. Monitor Deployment
```bash
# Check application status
argocd app get 2-broken-apps

# Watch pods come online
kubectl get pods -n default -w

# Verify specific deployments
kubectl get deployment order-service -n default
kubectl get deployment store-admin -n default
```

### 5. Check Health Status
```bash
# All pods should be running
kubectl get pods -n default | grep -E "(order-service|store-admin)"

# Check events for any issues
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20
```

---

## 📊 Impact Analysis

| Component | Status | Impact Level |
|-----------|--------|--------------|
| `order-service` | ❌ Failed | **Critical** - Blocks deployment |
| `store-admin` | ❌ Failed | **High** - ImagePullBackOff |
| `store-front` | ⚠️ Degraded | **Medium** - Depends on order-service |
| `product-service` | ✅ OK | **Low** - Independent |
| `makeline-service` | ⚠️ Degraded | **Medium** - Depends on order-service |

---

## 🔑 Key Learnings

1. **ArgoCD Error Messages:** The generic error "synchronization tasks are not valid" can indicate basic YAML/API syntax issues
2. **Validation First:** Always validate Kubernetes manifests before deploying:
   ```bash
   kubectl apply --dry-run=client -f <manifest>
   ```
3. **Source Control:** Issues in upstream repositories require coordination with repository owners
4. **Testing:** Test deployments should use intentionally broken manifests to validate notification workflows
5. **Dependency Awareness:** A single invalid resource can block entire application deployment; understand service dependencies

---

## 📝 Related Files

- **ArgoCD Application Definition:** `Act-3/argocd-test-app.yaml`
- **Source Repository:** https://github.com/dcasati/argocd-notification-examples.git
- **Problematic Manifest:** `apps/broken-aks-store-all-in-one.yaml`
- **Workflow Handler:** `.github/workflows/argocd-deployment-failure.yml`

---

## 🔗 References

- [ArgoCD Application CRD Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications)
- [Kubernetes API Versions](https://kubernetes.io/docs/reference/using-api/#api-versioning)
- [Kustomize Patching](https://kubectl.docs.kubernetes.io/references/kustomize/patches/)
- [ArgoCD Sync Phases and Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)

---

**Status:** ✅ Root Cause Identified | ⏳ Awaiting Remediation Decision  
**Next Steps:** Choose remediation option and implement fix
