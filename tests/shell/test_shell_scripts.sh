#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

export PYTHONPATH="$ROOT/scripts${PYTHONPATH:+:$PYTHONPATH}"
export ARTAGON_SKIP_GIT_CLEAN=1
export ARTAGON_SKIP_RELEASE_STEPS=1

echo "Running shell script sanity checks..."

# Basic linting of critical shell scripts
bash -n scripts/deploy/mvn_release.sh
bash -n scripts/deploy/mvn_deploy_snapshot.sh
bash -n scripts/deploy/mvn_check_ready.sh
bash -n scripts/security/mvn_update_security.sh
bash -n scripts/security/mvn_generate_checksums.sh
bash -n scripts/security/mvn_verify_checksums.sh

# CLI availability
scripts/artagon --help >/dev/null

echo "Shell script checks passed."
