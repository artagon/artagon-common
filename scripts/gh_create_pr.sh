#!/usr/bin/env bash
set -euo pipefail

# Create GitHub Pull Request from current branch
#
# Usage: ./scripts/gh_create_pr.sh [options]
#
# Automatically detects issue from branch name and fills PR template

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Options
DRAFT=false
BASE_BRANCH="main"

usage() {
    cat <<EOF
Usage: $0 [options]

Create a GitHub Pull Request from the current branch.

Options:
  -d, --draft           Create as draft PR
  -b, --base BRANCH     Base branch (default: main)
  -h, --help            Show this help message

Examples:
  $0                    Create PR from current branch
  $0 --draft            Create draft PR
  $0 --base develop     Create PR targeting develop branch

The script automatically:
  - Detects issue number from branch name
  - Generates PR title from branch and commits
  - Fills PR template
  - Links to related issue

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--draft)
            DRAFT=true
            shift
            ;;
        -b|--base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}ERROR: Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

# Check for required commands
require_commands "gh" "git" "jq" || exit 1

# Get current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || true)

if [[ -z "$CURRENT_BRANCH" ]]; then
    echo -e "${RED}ERROR: Not on a branch (detached HEAD)${NC}" >&2
    exit 1
fi

if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
    echo -e "${RED}ERROR: Cannot create PR from base branch '$BASE_BRANCH'${NC}" >&2
    echo "Please create a feature branch first" >&2
    exit 1
fi

echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

# Parse branch name to extract type and issue number
# Expected format: <type>/<issue>-<slug>
if [[ "$CURRENT_BRANCH" =~ ^([a-z]+)/([0-9]+)-(.+)$ ]]; then
    BRANCH_TYPE="${BASH_REMATCH[1]}"
    ISSUE_NUMBER="${BASH_REMATCH[2]}"
    BRANCH_SLUG="${BASH_REMATCH[3]}"
    echo -e "${CYAN}Detected: type=${BRANCH_TYPE}, issue=#${ISSUE_NUMBER}${NC}"
elif [[ "$CURRENT_BRANCH" =~ ^([a-z]+)/(.+)$ ]]; then
    BRANCH_TYPE="${BASH_REMATCH[1]}"
    ISSUE_NUMBER=""
    BRANCH_SLUG="${BASH_REMATCH[2]}"
    echo -e "${YELLOW}WARNING: No issue number detected in branch name${NC}"
else
    BRANCH_TYPE=""
    ISSUE_NUMBER=""
    BRANCH_SLUG="$CURRENT_BRANCH"
    echo -e "${YELLOW}WARNING: Branch name doesn't follow semantic convention${NC}"
    echo -e "${YELLOW}Expected format: <type>/<issue>-<description>${NC}"
fi

# Check if branch has been pushed
if ! git ls-remote --heads origin "$CURRENT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
    echo -e "${YELLOW}Branch not yet pushed to remote${NC}"
    read -p "Push branch now? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}Pushing branch to origin...${NC}"
        git push -u origin "$CURRENT_BRANCH"
        echo -e "${GREEN}✓ Branch pushed${NC}"
    else
        echo -e "${RED}ERROR: Branch must be pushed before creating PR${NC}" >&2
        exit 1
    fi
fi

# Check if PR already exists
if EXISTING_PR=$(gh pr view "$CURRENT_BRANCH" --json number 2>/dev/null); then
    PR_NUMBER=$(echo "$EXISTING_PR" | jq -r '.number')
    echo -e "${YELLOW}PR already exists: #${PR_NUMBER}${NC}"
    echo -e "${CYAN}View: gh pr view ${PR_NUMBER}${NC}"
    exit 0
fi

# Generate PR title from first commit or branch name
echo -e "${BLUE}Generating PR title...${NC}"

# Try to get the most recent commit message
if COMMIT_MSG=$(git log --format=%s -n 1 "$CURRENT_BRANCH" ^"origin/$BASE_BRANCH" 2>/dev/null); then
    # If commit follows semantic format, use it
    if [[ "$COMMIT_MSG" =~ ^[a-z]+(\([a-z]+\))?:\ .+ ]]; then
        PR_TITLE="$COMMIT_MSG"
    else
        # Generate from branch
        PR_TITLE="${BRANCH_TYPE}: ${BRANCH_SLUG//-/ }"
    fi
else
    # No commits yet, generate from branch
    PR_TITLE="${BRANCH_TYPE}: ${BRANCH_SLUG//-/ }"
fi

echo -e "${GREEN}PR Title: ${PR_TITLE}${NC}"

# Fetch issue details if available
ISSUE_TITLE=""
ISSUE_BODY=""
if [[ -n "$ISSUE_NUMBER" ]]; then
    echo -e "${BLUE}Fetching issue #${ISSUE_NUMBER}...${NC}"
    if ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json title,body 2>/dev/null); then
        ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
        ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body')
        echo -e "${CYAN}Issue: ${ISSUE_TITLE}${NC}"
    fi
fi

# Generate PR body
PR_BODY=$(cat <<EOF
## Description

<!-- Provide a clear description of your changes -->

${ISSUE_BODY:+Related to issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}
}
## Type of Change

- [ ] 🐛 Bug fix (\`fix\`)
- [ ] ✨ New feature (\`feat\`)
- [ ] 💥 Breaking change (\`feat!\` or \`fix!\`)
- [ ] 📝 Documentation update (\`docs\`)
- [ ] 🎨 Code style/formatting (\`style\`)
- [ ] ♻️  Refactoring (\`refactor\`)
- [ ] ⚡ Performance improvement (\`perf\`)
- [ ] ✅ Test update (\`test\`)
- [ ] 🔧 Build/CI update (\`build\`/\`ci\`)
- [ ] 🧹 Chore/maintenance (\`chore\`)

## Linked Issues

${ISSUE_NUMBER:+Closes #${ISSUE_NUMBER}}

## Changes Made

<!-- List the key changes -->

-
-
-

## Testing

- [ ] Ran existing tests
- [ ] Tested locally
- [ ] Added new tests

## Documentation

- [ ] Updated relevant documentation
- [ ] Updated README if needed
- [ ] Added code comments

## Checklist

- [ ] Semantic commit messages used
- [ ] Branch name follows convention
- [ ] All commits reference issue
- [ ] CI checks pass
- [ ] Self-reviewed code
- [ ] No secrets committed

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)

# Create PR
echo
echo -e "${BLUE}Creating Pull Request...${NC}"

PR_FLAGS=(
    "--title" "$PR_TITLE"
    "--body" "$PR_BODY"
    "--base" "$BASE_BRANCH"
)

if [[ "$DRAFT" == true ]]; then
    PR_FLAGS+=("--draft")
fi

if gh pr create "${PR_FLAGS[@]}"; then
    PR_NUMBER=$(gh pr view --json number -q '.number')
    echo
    echo -e "${GREEN}✓ Pull Request created successfully!${NC}"
    echo
    echo -e "${CYAN}PR #${PR_NUMBER}: ${PR_TITLE}${NC}"
    echo
    echo "View PR: gh pr view ${PR_NUMBER}"
    echo "Edit PR: gh pr edit ${PR_NUMBER}"
    echo "View in browser: gh pr view ${PR_NUMBER} --web"
    echo
    echo "Next steps:"
    echo "  1. Review the PR description and update if needed"
    echo "  2. Wait for CI checks to complete"
    echo "  3. Request review from maintainers"
    echo "  4. Address any review feedback"
else
    echo -e "${RED}✗ Failed to create Pull Request${NC}" >&2
    exit 1
fi
