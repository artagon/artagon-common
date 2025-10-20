#!/usr/bin/env bash
set -euo pipefail

# Create semantic branch from GitHub issue
#
# Usage: ./scripts/gh_create_issue_branch.sh <issue-number>
# Example: ./scripts/gh_create_issue_branch.sh 42
#
# Creates branch with format: <type>/<issue>-<slug>
# Example: feat/42-add-cpp26-support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <issue-number>

Create a semantic branch from a GitHub issue.

Arguments:
  issue-number    GitHub issue number

Examples:
  $0 42           Create branch from issue #42
  $0 --help       Show this help message

Branch Naming:
  feat/<issue>-<slug>      For features (label: enhancement)
  fix/<issue>-<slug>       For bugs (label: bug)
  docs/<issue>-<slug>      For documentation
  refactor/<issue>-<slug>  For refactoring
  test/<issue>-<slug>      For tests
  ci/<issue>-<slug>        For CI/CD changes
  chore/<issue>-<slug>     For maintenance

The script automatically detects the type from issue labels.

EOF
    exit 0
}

# Show help
if [[ ${#} -eq 0 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

# Check for gh CLI
require_commands "gh" "git" || exit 1

# Parse arguments
ISSUE_NUMBER="$1"

# Validate issue number
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}ERROR: Invalid issue number: $ISSUE_NUMBER${NC}" >&2
    echo "Issue number must be a positive integer" >&2
    exit 1
fi

echo -e "${BLUE}Fetching issue #${ISSUE_NUMBER}...${NC}"

# Fetch issue details
if ! ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json title,labels,state 2>&1); then
    echo -e "${RED}ERROR: Failed to fetch issue #${ISSUE_NUMBER}${NC}" >&2
    echo "$ISSUE_JSON" >&2
    exit 1
fi

# Parse issue details
ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_STATE=$(echo "$ISSUE_JSON" | jq -r '.state')
ISSUE_LABELS=$(echo "$ISSUE_JSON" | jq -r '.labels[].name' | tr '\n' ',' | sed 's/,$//')

# Check if issue is already closed
if [[ "$ISSUE_STATE" == "CLOSED" ]]; then
    echo -e "${YELLOW}WARNING: Issue #${ISSUE_NUMBER} is already closed${NC}" >&2
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo -e "${CYAN}Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}${NC}"
echo -e "${CYAN}Labels: ${ISSUE_LABELS:-none}${NC}"
echo

# Determine branch type from labels
BRANCH_TYPE=""

if echo "$ISSUE_LABELS" | grep -qi "bug"; then
    BRANCH_TYPE="fix"
elif echo "$ISSUE_LABELS" | grep -qi "enhancement\|feature"; then
    BRANCH_TYPE="feat"
elif echo "$ISSUE_LABELS" | grep -qi "documentation"; then
    BRANCH_TYPE="docs"
elif echo "$ISSUE_LABELS" | grep -qi "refactor"; then
    BRANCH_TYPE="refactor"
elif echo "$ISSUE_LABELS" | grep -qi "test"; then
    BRANCH_TYPE="test"
elif echo "$ISSUE_LABELS" | grep -qi "ci\|cd"; then
    BRANCH_TYPE="ci"
elif echo "$ISSUE_LABELS" | grep -qi "chore\|maintenance\|dependencies"; then
    BRANCH_TYPE="chore"
else
    # Default to feat if no matching label
    BRANCH_TYPE="feat"
    echo -e "${YELLOW}No matching label found, defaulting to 'feat'${NC}"
fi

# Create slug from title
# - Convert to lowercase
# - Remove special chars except hyphens
# - Replace spaces with hyphens
# - Remove leading/trailing hyphens
# - Collapse multiple hyphens
# - Limit to 50 chars
SLUG=$(echo "$ISSUE_TITLE" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 -]//g' | \
    sed 's/ /-/g' | \
    sed 's/^-*//;s/-*$//' | \
    sed 's/-\{2,\}/-/g' | \
    cut -c1-50 | \
    sed 's/-*$//')

# Construct branch name
BRANCH_NAME="${BRANCH_TYPE}/${ISSUE_NUMBER}-${SLUG}"

echo -e "${GREEN}Branch name: ${BRANCH_NAME}${NC}"
echo

# Check if branch already exists locally
if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}Branch '$BRANCH_NAME' already exists locally${NC}"
    read -p "Switch to existing branch? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout "$BRANCH_NAME"
        echo -e "${GREEN}Switched to branch '$BRANCH_NAME'${NC}"
    fi
    exit 0
fi

# Check if branch exists remotely
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
    echo -e "${YELLOW}Branch '$BRANCH_NAME' exists remotely${NC}"
    read -p "Check out remote branch? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git fetch origin
        git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
        echo -e "${GREEN}Checked out remote branch '$BRANCH_NAME'${NC}"
    fi
    exit 0
fi

# Get current branch for comparison
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}WARNING: You have uncommitted changes${NC}"
    git status --short
    echo
    read -p "Stash changes and create branch? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -m "Stashed before creating $BRANCH_NAME"
        echo -e "${GREEN}Changes stashed${NC}"
    else
        echo "Please commit or stash your changes first"
        exit 1
    fi
fi

# Create and switch to branch
echo -e "${BLUE}Creating branch from '${CURRENT_BRANCH}'...${NC}"

if git checkout -b "$BRANCH_NAME"; then
    echo -e "${GREEN}✓ Successfully created and switched to branch '$BRANCH_NAME'${NC}"
    echo
    echo "Next steps:"
    echo "  1. Make your changes"
    echo "  2. Commit with semantic message: git commit -m \"${BRANCH_TYPE}(<scope>): <subject>\""
    echo "  3. Push branch: git push -u origin $BRANCH_NAME"
    echo "  4. Create PR: ./scripts/gh_create_pr.sh"
    echo
    echo "Example commit message:"
    echo "  ${BRANCH_TYPE}(scope): ${ISSUE_TITLE}"
    echo "  "
    echo "  Closes #${ISSUE_NUMBER}"
else
    echo -e "${RED}✗ Failed to create branch${NC}" >&2
    exit 1
fi
