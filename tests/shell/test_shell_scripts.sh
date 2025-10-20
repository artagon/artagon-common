#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

export PYTHONPATH="$ROOT/scripts${PYTHONPATH:+:$PYTHONPATH}"
export ARTAGON_SKIP_GIT_CLEAN=1
export ARTAGON_SKIP_RELEASE_STEPS=1

echo "Running shell script sanity checks..."

# Basic linting of critical shell scripts
bash -n scripts/deploy/release.sh
bash -n scripts/deploy/deploy-snapshot.sh
bash -n scripts/deploy/check-deploy-ready.sh
bash -n scripts/security/mvn-update-dep-security.sh
bash -n scripts/security/generate-dependency-checksums.sh
bash -n scripts/security/verify-checksums.sh

# CLI availability
scripts/artagon --help >/dev/null

echo "Shell script checks passed."
