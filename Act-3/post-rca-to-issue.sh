#!/bin/bash
# Script to post root cause analysis to GitHub issue

set -e

ISSUE_NUMBER="${1:-12}"
REPO_OWNER="DevExpGbb"
REPO_NAME="agentic-platform-engineering"
COMMENT_FILE="Act-3/ROOT_CAUSE_ANALYSIS.md"

echo "Posting root cause analysis to issue #${ISSUE_NUMBER}..."

# Check if GitHub token is available
if [ -z "${GITHUB_TOKEN}" ] && [ -z "${GH_TOKEN}" ]; then
    echo "ERROR: No GitHub token found in environment"
    echo "Please set GITHUB_TOKEN or GH_TOKEN environment variable"
    echo ""
    echo "Alternatively, you can manually post the comment from: ${COMMENT_FILE}"
    echo "Or trigger the workflow: .github/workflows/post-rca-comment.yml"
    exit 1
fi

# Use GITHUB_TOKEN if available, otherwise GH_TOKEN
TOKEN="${GITHUB_TOKEN:-$GH_TOKEN}"

# Read the comment body and create JSON payload
COMMENT_BODY=$(cat "${COMMENT_FILE}" | jq -Rs .)

# Create the API request
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${ISSUE_NUMBER}/comments" \
  -d "{\"body\":${COMMENT_BODY}}"

echo ""
echo "Successfully posted root cause analysis to issue #${ISSUE_NUMBER}"
