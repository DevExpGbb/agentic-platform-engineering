# ArgoCD Deployment Failure Analysis

## Summary

This directory contains the root cause analysis for the ArgoCD deployment failure of the `2-broken-apps` application reported in [Issue #12](https://github.com/DevExpGbb/agentic-platform-engineering/issues/12).

## Quick Start

To post the analysis as a comment on the GitHub issue, use one of these methods:

### Method 1: GitHub CLI (Recommended)

```bash
gh issue comment 12 --body-file .github/ISSUE_12_ANALYSIS.md
```

### Method 2: GitHub Actions Workflow

Trigger the workflow manually from the Actions tab or via CLI:

```bash
gh workflow run post-issue-analysis.yml -f issue_number=12
```

### Method 3: Bash Script

Run the provided script:

```bash
./.github/scripts/post-to-issue.sh 12
```

### Method 4: Manual Copy-Paste

1. Open the issue: https://github.com/DevExpGbb/agentic-platform-engineering/issues/12
2. Copy the contents of `.github/ISSUE_12_ANALYSIS.md`
3. Paste into a new comment

## Files

- **ISSUE_12_ANALYSIS.md** - Complete root cause analysis and remediation recommendations
- **workflows/post-issue-analysis.yml** - GitHub Actions workflow to post the analysis
- **scripts/post-to-issue.sh** - Bash script to post the analysis
- **scripts/post-issue-analysis.js** - Node.js helper script
- **README_ANALYSIS.md** - This file

## Root Cause (TL;DR)

The deployment is failing due to an **invalid Kubernetes API version** in the manifest file:

**File:** `apps/broken-aks-store-all-in-one.yaml` (line 178) in the external repository  
**Issue:** `apiVersion: apps/v` should be `apiVersion: apps/v1`

This was intentionally broken for testing ArgoCD notification workflows (commit message: "break apiVersion formatting in deployment YAML").

## Remediation Options

1. **Fix the source repository** - Correct the `apiVersion` field in the YAML file
2. **Point to a different source** - Update the ArgoCD Application to use a working repository
3. **Use resource exclusion** - Temporarily exclude the broken deployment while investigating

See the full analysis in `ISSUE_12_ANALYSIS.md` for detailed remediation steps.
