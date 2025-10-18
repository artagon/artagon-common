#!/bin/bash

# Check if project is ready for deployment
# Usage: ./artagon-common/scripts/check-deploy-ready.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "Deployment Readiness Check"
echo "=========================================="
echo ""

ERRORS=0

# Check 1: GPG key available
echo -n "[1/8] Checking GPG key... "
if gpg --list-secret-keys >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAIL - No GPG key found"
    ERRORS=$((ERRORS+1))
fi

# Check 2: Maven settings
echo -n "[2/8] Checking Maven settings... "
if [ -f ~/.m2/settings.xml ] && grep -q "ossrh" ~/.m2/settings.xml; then
    echo "✓ OK"
else
    echo "✗ FAIL - OSSRH server not configured in ~/.m2/settings.xml"
    ERRORS=$((ERRORS+1))
fi

# Check 3: POMs have required metadata
echo -n "[3/8] Checking POM metadata... "
REQUIRED=("name" "description" "url" "licenses" "developers" "scm")
for field in "${REQUIRED[@]}"; do
    if ! grep -q "<$field>" artagon-bom/pom.xml; then
        echo "✗ FAIL - artagon-bom missing <$field>"
        ERRORS=$((ERRORS+1))
    fi
done
echo "✓ OK"

# Check 4: Build succeeds
echo -n "[4/8] Testing build... "
if mvn clean verify -q >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAIL - Build failed"
    ERRORS=$((ERRORS+1))
fi

# Check 5: No SNAPSHOT dependencies (for release)
echo -n "[5/8] Checking for SNAPSHOT dependencies... "
if mvn dependency:tree | grep -q ":.*:.*SNAPSHOT"; then
    echo "⚠ WARNING - SNAPSHOT dependencies found (OK for snapshot deploy, not for release)"
else
    echo "✓ OK"
fi

# Check 6: Git status
echo -n "[6/8] Checking git status... "
if git status --porcelain | grep -q .; then
    echo "⚠ WARNING - Uncommitted changes"
else
    echo "✓ OK"
fi

# Check 7: On main branch
echo -n "[7/8] Checking git branch... "
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
    echo "✓ OK"
else
    echo "⚠ WARNING - Not on main branch (current: $BRANCH)"
fi

# Check 8: Security files exist
echo -n "[8/8] Checking security files... "
if [ -f artagon-parent/security/pgp-trusted-keys.list ] && \
   [ -f artagon-parent/security/bom-checksums.csv ]; then
    echo "✓ OK"
else
    echo "⚠ WARNING - Security files missing"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ Ready for deployment!"
    echo "=========================================="
    echo ""
    echo "To deploy snapshot:"
    echo "  ./artagon-common/scripts/deploy-snapshot.sh"
    echo ""
    echo "To release:"
    echo "  ./artagon-common/scripts/release.sh 1.0.0"
    exit 0
else
    echo "✗ $ERRORS error(s) found - fix before deploying"
    echo "=========================================="
    exit 1
fi
