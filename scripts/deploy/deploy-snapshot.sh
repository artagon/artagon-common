#!/usr/bin/env bash
set -euo pipefail

# Deploy Artagon BOM and Parent to OSSRH Snapshots
# Usage: ./artagon-common/scripts/deploy-snapshot.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Deploying Artagon Snapshots to OSSRH"
echo "=========================================="

cd "$PROJECT_ROOT"

# Check we're on a SNAPSHOT version
if ! grep -q "SNAPSHOT" artagon-bom/pom.xml; then
    echo "ERROR: artagon-bom is not a SNAPSHOT version"
    exit 1
fi

if ! grep -q "SNAPSHOT" artagon-parent/pom.xml; then
    echo "ERROR: artagon-parent is not a SNAPSHOT version"
    exit 1
fi

# Clean and verify
echo ""
echo "1. Running clean verify..."
mvn clean verify

# Deploy
echo ""
echo "2. Deploying to OSSRH snapshots..."
mvn deploy -Possrh-deploy,artagon-oss-release -DskipTests

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Snapshots available at:"
echo "  https://s01.oss.sonatype.org/content/repositories/snapshots/org/artagon/"
