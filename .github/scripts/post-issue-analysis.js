#!/usr/bin/env node

/**
 * Post the analysis from ISSUE_12_ANALYSIS.md as a comment on issue #12
 * This script is meant to be run from a GitHub Actions workflow with the github-script action
 * 
 * Usage in workflow:
 * - uses: actions/github-script@v7
 *   with:
 *     script: |
 *       const fs = require('fs');
 *       const commentBody = fs.readFileSync('.github/ISSUE_12_ANALYSIS.md', 'utf8');
 *       await github.rest.issues.createComment({
 *         owner: context.repo.owner,
 *         repo: context.repo.repo,
 *         issue_number: 12,
 *         body: commentBody
 *       });
 */

const fs = require('fs');
const path = require('path');

// Read the analysis file
const analysisFile = path.join(__dirname, '..', 'ISSUE_12_ANALYSIS.md');

if (!fs.existsSync(analysisFile)) {
  console.error(`Error: Analysis file not found at ${analysisFile}`);
  process.exit(1);
}

const commentBody = fs.readFileSync(analysisFile, 'utf8');

// Remove the note section at the end
const cleanedBody = commentBody.replace(/---\n\n\*\*Note:\*\*.*$/s, '').trim();

console.log('Analysis file loaded successfully');
console.log(`Comment length: ${cleanedBody.length} characters`);
console.log('\nTo post this comment, use:');
console.log('gh issue comment 12 --body-file .github/ISSUE_12_ANALYSIS.md');
console.log('\nOr use this in a GitHub Actions workflow with github-script action');

// Export for use in GitHub Actions
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { commentBody: cleanedBody };
}
