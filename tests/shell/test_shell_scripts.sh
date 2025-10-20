#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "Running shell script sanity checks..."

# Basic linting of critical shell scripts
bash -n scripts/deploy/release.sh
bash -n scripts/deploy/deploy-snapshot.sh
bash -n scripts/deploy/check-deploy-ready.sh
bash -n scripts/security/mvn-update-dep-security.sh
bash -n scripts/security/generate-dependency-checksums.sh
bash -n scripts/security/verify-checksums.sh

# CLI smoke tests (dry-run to avoid side effects)
scripts/artagon --help >/dev/null
scripts/artagon --dry-run java release run --version 0.0.1 >/dev/null
scripts/artagon --dry-run java release branch stage >/dev/null
scripts/artagon --dry-run java snapshot publish >/dev/null
scripts/artagon --dry-run java security update >/dev/null
scripts/artagon --dry-run java gh protect --branch main >/dev/null

echo "Shell script checks passed."
