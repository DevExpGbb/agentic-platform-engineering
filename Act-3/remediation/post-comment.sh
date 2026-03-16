#!/bin/bash

# Quick Post Comment Script
# This script posts the remediation comment to GitHub issue #12
# 
# Prerequisites:
# - GitHub CLI (gh) installed
# - Authenticated with: gh auth login
# 
# Usage:
#   cd /path/to/repo
#   bash Act-3/remediation/post-comment.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMENT_FILE="$SCRIPT_DIR/issue-12-argocd-deployment-failure.md"

ISSUE_NUMBER=12
REPO="DevExpGbb/agentic-platform-engineering"

echo "═══════════════════════════════════════════════════════════"
echo "  ArgoCD Deployment Failure - Post Remediation Comment"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo ""
    echo "Install it from: https://cli.github.com/"
    echo ""
    echo "Or use an alternative method from README.md"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo ""
    echo "Please authenticate with: gh auth login"
    echo ""
    exit 1
fi

# Check if comment file exists
if [ ! -f "$COMMENT_FILE" ]; then
    echo "❌ Error: Comment file not found at: $COMMENT_FILE"
    exit 1
fi

echo "✓ GitHub CLI installed and authenticated"
echo "✓ Comment file found: $(basename $COMMENT_FILE)"
echo ""
echo "Repository: $REPO"
echo "Issue: #$ISSUE_NUMBER"
echo ""
echo "───────────────────────────────────────────────────────────"
read -p "Post comment to issue #$ISSUE_NUMBER? (y/N): " -n 1 -r
echo ""
echo "───────────────────────────────────────────────────────────"

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "❌ Cancelled by user"
    exit 0
fi

echo ""
echo "Posting comment..."
echo ""

# Post the comment
gh issue comment "$ISSUE_NUMBER" \
    --repo "$REPO" \
    --body-file "$COMMENT_FILE"

echo ""
echo "✅ Comment posted successfully!"
echo ""
echo "View at: https://github.com/$REPO/issues/$ISSUE_NUMBER"
echo ""
