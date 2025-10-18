#!/bin/bash
set -e

# Release artifacts from Nexus staging to Maven Central
# Usage: ./artagon-common/scripts/nexus-release.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "Nexus Staging Repository Management"
echo "=========================================="
echo ""

# List staging repositories
echo "Listing staging repositories..."
mvn nexus-staging:rc-list -Possrh-deploy

echo ""
read -p "Do you want to RELEASE the staging repository? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Release
echo ""
echo "Releasing staging repository to Maven Central..."
mvn nexus-staging:release -Possrh-deploy

echo ""
echo "=========================================="
echo "Release Complete!"
echo "=========================================="
echo ""
echo "Artifacts will sync to Maven Central in 2-4 hours."
echo ""
echo "Check status at:"
echo "  https://repo1.maven.org/maven2/org/artagon/"
echo "  https://search.maven.org/search?q=g:org.artagon"
