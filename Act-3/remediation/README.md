# ArgoCD Deployment Failure - Remediation Documentation

This directory contains root cause analysis and remediation recommendations for ArgoCD deployment failures.

## How to Post Remediation Comments to GitHub Issues

### Option 1: Using the Helper Script (Easiest)

```bash
# From the repository root
bash Act-3/remediation/post-comment.sh
```

This interactive script will:
- Check if GitHub CLI is installed and authenticated
- Confirm before posting
- Post the comment to issue #12
- Show you the URL to view the comment

### Option 2: Using GitHub CLI Directly

```bash
# Authenticate with GitHub (if not already)
gh auth login

# Post the comment
gh issue comment 12 \
  --repo DevExpGbb/agentic-platform-engineering \
  --body-file Act-3/remediation/issue-12-argocd-deployment-failure.md
```

### Option 2: Using GitHub CLI Directly

```bash
# Authenticate with GitHub (if not already)
gh auth login

# Post the comment
gh issue comment 12 \
  --repo DevExpGbb/agentic-platform-engineering \
  --body-file Act-3/remediation/issue-12-argocd-deployment-failure.md
```

### Option 3: Using GitHub Actions Workflow

A workflow has been created at `.github/workflows/post-issue-comment.yml` that can be manually triggered:

1. Go to Actions tab in GitHub
2. Select "Post Issue Comment" workflow  
3. Click "Run workflow"
4. Enter:
   - Issue number: `12`
   - Comment file: `Act-3/remediation/issue-12-argocd-deployment-failure.md`
5. Click "Run workflow"

### Option 3: Using GitHub Actions Workflow

A workflow has been created at `.github/workflows/post-issue-comment.yml` that can be manually triggered:

1. Go to Actions tab in GitHub
2. Select "Post Issue Comment" workflow  
3. Click "Run workflow"
4. Enter:
   - Issue number: `12`
   - Comment file: `Act-3/remediation/issue-12-argocd-deployment-failure.md`
5. Click "Run workflow"

### Option 4: Using GitHub API directly

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Post the comment
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/DevExpGbb/agentic-platform-engineering/issues/12/comments \
  -d @<(jq -Rs '{"body": .}' < Act-3/remediation/issue-12-argocd-deployment-failure.md)
```

### Option 4: Using GitHub API directly

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Post the comment
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/DevExpGbb/agentic-platform-engineering/issues/12/comments \
  -d @<(jq -Rs '{"body": .}' < Act-3/remediation/issue-12-argocd-deployment-failure.md)
```

### Option 5: Manual Copy-Paste

1. Open the file: `Act-3/remediation/issue-12-argocd-deployment-failure.md`
2. Copy the entire contents
3. Go to https://github.com/DevExpGbb/agentic-platform-engineering/issues/12
4. Paste into a new comment
5. Click "Comment"

## Files in This Directory

- `issue-12-argocd-deployment-failure.md` - Comprehensive root cause analysis and remediation recommendations for the `2-broken-apps` ArgoCD deployment failure
- `post-comment.sh` - Interactive helper script to post the comment (requires gh CLI)
- `README.md` - This file, with instructions on how to post the remediation comments
