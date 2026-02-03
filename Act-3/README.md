# Act-3: ArgoCD Deployment Monitoring & Root Cause Analysis

This directory contains ArgoCD application definitions and associated troubleshooting documentation for deployment failures.

## Contents

### ArgoCD Application Definitions
- **[argocd-test-app.yaml](./argocd-test-app.yaml)** - Test ArgoCD application definition for `2-broken-apps`

### Root Cause Analysis Documentation
- **[ISSUE-12-FINDINGS.md](./ISSUE-12-FINDINGS.md)** - Quick summary of findings for Issue #12
- **[RCA-2-broken-apps.md](./RCA-2-broken-apps.md)** - Comprehensive root cause analysis for the `2-broken-apps` deployment failure

## Quick Links

- [Issue #12: ArgoCD Deployment Failed](https://github.com/DevExpGbb/agentic-platform-engineering/issues/12)
- [ArgoCD Deployment Failure Workflow](../.github/workflows/argocd-deployment-failure.yml)
- [ArgoCD Notifications Setup](../.github/argocd/SETUP.md)

## Overview

This act demonstrates automated ArgoCD deployment monitoring and issue creation workflow:

1. **ArgoCD detects deployment failure** (sync failed or health degraded)
2. **ArgoCD Notifications** sends webhook to GitHub
3. **GitHub Actions workflow** creates/updates issue automatically
4. **Copilot Agent** analyzes the issue and provides root cause analysis

## Current Status: Issue #12 Analysis

**Application:** `2-broken-apps`  
**Status:** Root cause identified ✅  
**Issues Found:** 2 critical errors in upstream repository

### Quick Summary

Two issues identified in the source repository (https://github.com/dcasati/argocd-notification-examples.git):

1. **Invalid API Version** (Line 178) - Critical
   - `apiVersion: apps/v` should be `apiVersion: apps/v1`
   
2. **Typo in Image Name** (Line 475) - High
   - `store-dmin` should be `store-admin`

📖 **[View Full Analysis](./ISSUE-12-FINDINGS.md)**

## Troubleshooting

To investigate ArgoCD deployment issues:

```bash
# Check application status
argocd app get 2-broken-apps

# Check pods in namespace
kubectl get pods -n default

# Describe failed pods
kubectl describe pods -n default

# Get pod logs
kubectl logs -n default <pod-name>

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'
```

## Related Documentation

- [ArgoCD Notifications Configuration](../.github/argocd/argocd-notifications-config.yaml)
- [Setup Guide](../.github/argocd/SETUP.md)
