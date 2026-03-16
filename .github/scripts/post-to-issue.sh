#!/bin/bash

# Post Issue Analysis to GitHub
# This script posts the root cause analysis to a GitHub issue

set -e

ISSUE_NUMBER="${1:-12}"
ANALYSIS_FILE=".github/ISSUE_12_ANALYSIS.md"
REPO_OWNER="DevExpGbb"
REPO_NAME="agentic-platform-engineering"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "  GitHub Issue Analysis Poster"
echo "================================================"
echo ""

# Check if analysis file exists
if [ ! -f "$ANALYSIS_FILE" ]; then
    echo -e "${RED}Error: Analysis file not found at $ANALYSIS_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Analysis file found${NC}"

# Clean the comment body (remove the note section)
COMMENT_BODY=$(sed '/^---$/,$ d' "$ANALYSIS_FILE" | sed -e 's/$/\\n/' | tr -d '\n')

# Method 1: Try gh CLI
if command -v gh &> /dev/null && [ -n "$GITHUB_TOKEN" ] || gh auth status &> /dev/null 2>&1; then
    echo -e "${GREEN}Using GitHub CLI...${NC}"
    gh issue comment "$ISSUE_NUMBER" --body-file "$ANALYSIS_FILE"
    echo -e "${GREEN}✓ Comment posted successfully using gh CLI!${NC}"
    exit 0
fi

# Method 2: Try curl with GITHUB_TOKEN
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${GREEN}Using curl with GITHUB_TOKEN...${NC}"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE_NUMBER/comments" \
        -d @<(jq -Rs '{body: .}' < "$ANALYSIS_FILE"))
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "201" ]; then
        echo -e "${GREEN}✓ Comment posted successfully using curl!${NC}"
        COMMENT_URL=$(echo "$BODY" | jq -r '.html_url')
        echo "Comment URL: $COMMENT_URL"
        exit 0
    else
        echo -e "${RED}✗ Failed to post comment. HTTP code: $HTTP_CODE${NC}"
        echo "$BODY" | jq .
        exit 1
    fi
fi

# Method 3: Provide instructions for manual posting
echo -e "${YELLOW}No authentication method available.${NC}"
echo ""
echo "To post this analysis to issue #$ISSUE_NUMBER, use one of these methods:"
echo ""
echo "Method 1 - GitHub CLI:"
echo "  gh issue comment $ISSUE_NUMBER --body-file $ANALYSIS_FILE"
echo ""
echo "Method 2 - GitHub Web UI:"
echo "  1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/issues/$ISSUE_NUMBER"
echo "  2. Copy the contents of: $ANALYSIS_FILE"
echo "  3. Paste into a new comment"
echo ""
echo "Method 3 - Trigger the workflow:"
echo "  gh workflow run post-issue-analysis.yml -f issue_number=$ISSUE_NUMBER"
echo ""
echo "Method 4 - Use curl with your token:"
echo "  export GITHUB_TOKEN=your_token_here"
echo "  bash .github/scripts/post-to-issue.sh $ISSUE_NUMBER"
echo ""

exit 1
