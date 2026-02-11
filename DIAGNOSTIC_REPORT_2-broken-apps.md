# ArgoCD Deployment Failure: Diagnostic Report
## Application: `2-broken-apps`

**Report Date**: 2026-02-03  
**Investigated By**: GitHub Copilot Agent  
**Status**: Root Cause Identified

---

## Executive Summary

The ArgoCD application `2-broken-apps` is experiencing deployment failures due to **invalid Kubernetes manifest syntax** in the source repository. The investigation identified two critical errors in the manifest file that prevent successful synchronization.

**Current Status**: 
- Health Status: `Degraded`
- Sync Status: `OutOfSync`
- Error: "one or more synchronization tasks are not valid (retried 2 times)"

**Root Cause**: Invalid YAML syntax in the Kubernetes manifest files from the external repository.

---

## Investigation Summary

### Application Configuration

The ArgoCD application references the following external repository:
- **Repository**: `https://github.com/dcasati/argocd-notification-examples.git`
- **Path**: `apps/`
- **Revision**: `8cd04df204028ff78613a69fdb630625864037c6`
- **Target File**: `apps/broken-aks-store-all-in-one.yaml`

### Root Causes Identified

After cloning and analyzing the external repository, two critical syntax errors were found in the manifest file `apps/broken-aks-store-all-in-one.yaml`:

#### 🔴 Issue #1: Incomplete API Version (Line 178)

**Location**: `apps/broken-aks-store-all-in-one.yaml:178`

**Current (Invalid)**:
```yaml
apiVersion: apps/v
kind: Deployment
metadata:
  name: order-service
```

**Should Be**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
```

**Impact**: 
- Kubernetes API server rejects the manifest due to invalid API version
- The `order-service` Deployment cannot be created
- Blocks the entire synchronization process

**Error Type**: Syntax error - incomplete API version specification

---

#### 🔴 Issue #2: Typo in Container Image Name (Line 475)

**Location**: `apps/broken-aks-store-all-in-one.yaml:475`

**Current (Invalid)**:
```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-dmin:2.1.0
```

**Should Be**:
```yaml
containers:
  - name: store-admin
    image: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
```

**Impact**:
- Container image `store-dmin` does not exist in the registry (typo: missing 'a')
- The `store-admin` pod fails to pull the image
- Pod enters `ImagePullBackOff` or `ErrImagePull` state
- Application health becomes `Degraded`

**Error Type**: Configuration error - incorrect image reference

---

## Why ArgoCD Reports "Invalid Synchronization Tasks"

ArgoCD performs validation of Kubernetes manifests before applying them to the cluster. The validation process:

1. **Syntax Validation**: Checks if YAML is well-formed and contains valid Kubernetes API objects
2. **API Server Validation**: Sends manifests to the Kubernetes API server for validation
3. **Dry-Run Check**: Attempts a dry-run apply to detect issues before actual deployment

**Issue #1** (incomplete API version) fails at the **Syntax/API Validation** stage because:
- `apiVersion: apps/v` is not a valid Kubernetes API version
- The API server cannot parse or validate the resource
- ArgoCD marks the synchronization task as "invalid" and retries

**Issue #2** (typo in image name) would fail at the **Runtime** stage after Issue #1 is fixed:
- The manifest syntax is valid, so it passes validation
- However, when Kubernetes tries to create the pod, it cannot pull the image
- This causes the health check to report `Degraded` status

---

## Recommended Remediation Approach

### Option 1: Fix the Source Repository (Recommended)

**Action**: Submit a pull request to `https://github.com/dcasati/argocd-notification-examples` to fix the manifest errors.

**Steps**:
1. Fork the repository `dcasati/argocd-notification-examples`
2. Fix both issues in `apps/broken-aks-store-all-in-one.yaml`:
   - Line 178: Change `apiVersion: apps/v` to `apiVersion: apps/v1`
   - Line 475: Change `store-dmin` to `store-admin`
3. Test the manifest locally:
   ```bash
   kubectl apply --dry-run=client -f apps/broken-aks-store-all-in-one.yaml
   kubectl apply --dry-run=server -f apps/broken-aks-store-all-in-one.yaml
   ```
4. Submit pull request to the upstream repository
5. Wait for the PR to be merged (or use your fork as the source)
6. Update ArgoCD application to point to the fixed repository

**Pros**:
- Fixes the root cause permanently
- Benefits other users of the repository
- Maintains GitOps best practices

**Cons**:
- Depends on external repository maintainer approval
- Takes time for PR review and merge

---

### Option 2: Use a Forked/Local Copy

**Action**: Create a fork or local copy of the repository with fixes applied.

**Steps**:
1. Fork `dcasati/argocd-notification-examples` to your organization/account
2. Apply the fixes to your fork
3. Update the ArgoCD Application manifest to point to your fork:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR-ORG/argocd-notification-examples.git
       targetRevision: main
       path: apps
   ```
4. Sync the ArgoCD application

**Pros**:
- Immediate control over the fix
- No dependency on external maintainers
- Can be done within your team

**Cons**:
- Creates a fork that needs to be maintained
- Diverges from the upstream repository

---

### Option 3: Override with Kustomize

**Action**: Use Kustomize patches to override the broken manifest without modifying the source repository.

**Steps**:
1. Create a Kustomize overlay directory in your repository:
   ```
   overlays/
     broken-apps-fix/
       kustomization.yaml
       patch-order-service.yaml
       patch-store-admin.yaml
   ```

2. Create `kustomization.yaml`:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - https://github.com/dcasati/argocd-notification-examples//apps?ref=main
   patches:
     - path: patch-order-service.yaml
     - path: patch-store-admin.yaml
   ```

3. Create `patch-order-service.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: order-service
   ```

4. Create `patch-store-admin.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: store-admin
   spec:
     template:
       spec:
         containers:
           - name: store-admin
             image: ghcr.io/azure-samples/aks-store-demo/store-admin:2.1.0
   ```

5. Update ArgoCD Application to use the Kustomize overlay

**Pros**:
- No need to fork the repository
- Fixes are version-controlled in your own repository
- Easy to maintain and review

**Cons**:
- Adds complexity with Kustomize layers
- Still depends on the source repository for base resources

---

## Verification Steps

After applying the fix, verify the deployment with these commands:

```bash
# 1. Check ArgoCD application status
argocd app get 2-broken-apps

# Expected: Health Status: Healthy, Sync Status: Synced

# 2. Verify all pods are running
kubectl get pods -n default | grep -E "(order-service|store-admin|product-service|store-front|makeline-service|mongodb|rabbitmq)"

# Expected: All pods in Running state

# 3. Check for image pull errors
kubectl get pods -n default -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "ImagePullBackOff" or .status.containerStatuses[]?.state.waiting.reason == "ErrImagePull") | .metadata.name'

# Expected: No output (no pods with image pull errors)

# 4. Verify deployment health
kubectl get deployments -n default

# Expected: All deployments show READY status

# 5. Check ArgoCD sync history
argocd app history 2-broken-apps

# Expected: Latest sync shows SUCCESS
```

---

## Additional Recommendations

### 1. Implement Pre-Deployment Validation

Add CI/CD checks to validate Kubernetes manifests before they reach ArgoCD:

```yaml
# Example GitHub Actions workflow
name: Validate Kubernetes Manifests
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate YAML syntax
        run: |
          find . -name "*.yaml" -o -name "*.yml" | xargs yamllint
      - name: Validate Kubernetes resources
        run: |
          kubectl apply --dry-run=client -f apps/
          kubectl apply --dry-run=server -f apps/
```

### 2. Use ArgoCD Resource Hooks for Health Checks

Configure custom health checks in ArgoCD to detect issues faster:

```yaml
# In ArgoCD Application
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
    retry:
      limit: 5  # Increase retry limit for transient issues
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m
```

### 3. Monitor Image Availability

Implement monitoring to check if container images exist before deployment:

```bash
# Script to validate images exist
#!/bin/bash
for image in $(yq eval '.spec.template.spec.containers[].image' deployment.yaml); do
  docker pull "$image" --quiet || echo "ERROR: Image not found: $image"
done
```

---

## Conclusion

The ArgoCD deployment failure for `2-broken-apps` is caused by two manifest errors in the source repository:
1. **Incomplete API version** (`apps/v` instead of `apps/v1`) on line 178
2. **Typo in image name** (`store-dmin` instead of `store-admin`) on line 475

**Recommended Next Steps**:
1. ✅ Choose remediation approach (Option 1 recommended for long-term solution)
2. ✅ Apply the fix according to the chosen approach
3. ✅ Verify the deployment using the verification steps provided
4. ✅ Implement additional recommendations to prevent similar issues

**Estimated Time to Fix**: 15-30 minutes (depending on chosen approach)

---

**Note**: This is a diagnostic report only. No remediation has been applied to the source repository or ArgoCD configuration. The fixes described above should be implemented by the platform engineering team.
