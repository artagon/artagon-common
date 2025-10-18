#!/usr/bin/env bash
set -euo pipefail

# Automated: create GitHub repo via gh CLI, set SSH remote, push main.
# Fallbacks to HTTPS if SSH not desired or not configured.
#
# Prereqs:
#   - gh (GitHub CLI) authenticated: `gh auth login`
#   - git installed
#   - An SSH key added to your GitHub account for SSH pushes (optional but recommended)
#
# Usage examples:
#   ./auto_create_and_push.sh --repo my-project --public --ssh
#   ./auto_create_and_push.sh --repo my-app --private --https --description "My awesome app"
#   ./auto_create_and_push.sh --owner myorg --repo api-server --private --message "Initial commit"
#
# Flags:
#   --owner <org|user>        GitHub owner (defaults to your gh auth user)
#   --repo  <name>            Repository name (required)
#   --public|--private        Visibility (default: public)
#   --ssh|--https             Remote protocol (default: ssh)
#   --description <text>      Repository description (optional)
#   --message <text>          Initial commit message (default: "Initial commit")
#   --force                   If repo exists, skip create and just push to it
#   --no-prompt               Do not prompt; fail if info missing
#   --no-auto-cd              Don't auto-cd into matching subdirectory

OWNER=""
REPO=""
VISIBILITY="public"
PROTOCOL="ssh"
DESCRIPTION=""
COMMIT_MESSAGE="Initial commit"
FORCE=0
NOPROMPT=0
NO_AUTO_CD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2;;
    --repo) REPO="$2"; shift 2;;
    --public) VISIBILITY="public"; shift;;
    --private) VISIBILITY="private"; shift;;
    --ssh) PROTOCOL="ssh"; shift;;
    --https) PROTOCOL="https"; shift;;
    --description) DESCRIPTION="$2"; shift 2;;
    --message) COMMIT_MESSAGE="$2"; shift 2;;
    --force) FORCE=1; shift;;
    --no-prompt) NOPROMPT=1; shift;;
    --no-auto-cd) NO_AUTO_CD=1; shift;;
    -h|--help)
      cat << 'EOF'
Usage: auto_create_and_push.sh --repo <name> [options]

Required:
  --repo <name>              Repository name

Options:
  --owner <org|user>         GitHub owner (default: current gh user)
  --public                   Create public repo (default)
  --private                  Create private repo
  --ssh                      Use SSH protocol (default)
  --https                    Use HTTPS protocol
  --description <text>       Repository description
  --message <text>           Initial commit message (default: "Initial commit")
  --force                    Skip repo creation if it exists
  --no-prompt                Non-interactive mode
  --no-auto-cd               Don't auto-cd into matching subdirectory
  -h, --help                 Show this help

Examples:
  auto_create_and_push.sh --repo my-project --private
  auto_create_and_push.sh --repo api --owner myorg --description "REST API" --private
EOF
      exit 0;;
    *) echo "ERROR: Unknown argument: $1" >&2; exit 1;;
  esac
done

# Ensure gh is available
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) not found. Install from https://cli.github.com/ and run 'gh auth login'." >&2
  exit 1
fi

# Ensure git is available
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found. Please install git." >&2
  exit 1
fi

# Get repo name
if [[ -z "$REPO" ]]; then
  if [[ $NOPROMPT -eq 1 ]]; then
    echo "ERROR: --repo is required in non-interactive mode" >&2
    exit 1
  fi
  read -rp "Repository name: " REPO
  if [[ -z "$REPO" ]]; then
    echo "ERROR: Repository name cannot be empty" >&2
    exit 1
  fi
fi

# Validate repo name format
if [[ ! "$REPO" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "ERROR: Invalid repo name. Use only letters, numbers, dots, hyphens, and underscores." >&2
  exit 1
fi

# Get owner from gh auth if not provided
if [[ -z "$OWNER" ]]; then
  OWNER="$(gh api user --jq .login 2>/dev/null || true)"
fi

if [[ -z "$OWNER" ]]; then
  if [[ $NOPROMPT -eq 1 ]]; then
    echo "ERROR: Could not determine owner. Use --owner or ensure 'gh auth login' is configured." >&2
    exit 1
  fi
  read -rp "GitHub owner (user/org): " OWNER
  if [[ -z "$OWNER" ]]; then
    echo "ERROR: Owner cannot be empty" >&2
    exit 1
  fi
fi

echo ""
echo "Configuration:"
echo "  Owner:       $OWNER"
echo "  Repository:  $REPO"
echo "  Visibility:  $VISIBILITY"
echo "  Protocol:    $PROTOCOL"
[[ -n "$DESCRIPTION" ]] && echo "  Description: $DESCRIPTION"
echo ""

# Prepare remote URLs
SSH_URL="git@github.com:${OWNER}/${REPO}.git"
HTTPS_URL="https://github.com/${OWNER}/${REPO}.git"
REMOTE_URL="$SSH_URL"
if [[ "$PROTOCOL" == "https" ]]; then
  REMOTE_URL="$HTTPS_URL"
fi

# Create repo unless --force or it already exists
if [[ $FORCE -eq 1 ]]; then
  echo "Skipping repo creation due to --force."
else
  if gh repo view "${OWNER}/${REPO}" >/dev/null 2>&1; then
    echo "Repository ${OWNER}/${REPO} already exists."
  else
    echo "Creating repository ${OWNER}/${REPO} (${VISIBILITY})..."
    CREATE_CMD="gh repo create ${OWNER}/${REPO} --${VISIBILITY}"
    [[ -n "$DESCRIPTION" ]] && CREATE_CMD="$CREATE_CMD --description \"$DESCRIPTION\""
    CREATE_CMD="$CREATE_CMD --confirm"
    eval "$CREATE_CMD"
  fi
fi

# Auto-cd into subdirectory matching repo name if it exists
if [[ $NO_AUTO_CD -eq 0 ]] && [[ -d "./${REPO}" ]]; then
  echo "Auto-changing to ./${REPO} directory..."
  cd "./${REPO}"
fi

# Init git if needed
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Initializing local git repo..."
  git init -b main
else
  # If repo exists, ensure we're on main branch (rename master if needed)
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  if [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "Renaming branch 'master' to 'main'..."
    git branch -m master main
  elif [[ "$CURRENT_BRANCH" != "main" ]] && [[ -n "$CURRENT_BRANCH" ]]; then
    echo "Warning: Currently on branch '$CURRENT_BRANCH', not 'main'"
  fi
fi

# Ensure initial commit
if ! git log >/dev/null 2>&1; then
  echo "Creating initial commit..."
  git add .
  git commit -m "$COMMIT_MESSAGE"
else
  echo "Found existing commits."
fi

# Configure remote
if git remote get-url origin >/dev/null 2>&1; then
  echo "Updating 'origin' to ${REMOTE_URL}"
  git remote set-url origin "${REMOTE_URL}"
else
  echo "Adding 'origin' -> ${REMOTE_URL}"
  git remote add origin "${REMOTE_URL}"
fi

# Push main
echo "Pushing main branch to ${REMOTE_URL}..."
git push -u origin main

echo ""
echo "✓ Successfully pushed to ${OWNER}/${REPO}"
echo "  View at: https://github.com/${OWNER}/${REPO}"
echo "  Actions: https://github.com/${OWNER}/${REPO}/actions"
