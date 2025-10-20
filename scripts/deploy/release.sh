#!/usr/bin/env bash
set -euo pipefail

# Release Artagon BOM and Parent to Maven Central
# Usage: ./artagon-common/scripts/release.sh <version>
# Example: ./artagon-common/scripts/release.sh 1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

RELEASE_VERSION=$1
NEXT_VERSION="${RELEASE_VERSION%.*}.$((${RELEASE_VERSION##*.}+1))-SNAPSHOT"

echo "=========================================="
echo "Releasing Artagon $RELEASE_VERSION"
echo "Next version: $NEXT_VERSION"
echo "=========================================="

cd "$PROJECT_ROOT"

# Pre-flight checks
echo ""
echo "Pre-flight checks..."

if git status --porcelain | grep .; then
    echo "ERROR: Working directory is not clean. Commit or stash changes."
    exit 1
fi

CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "ERROR: Detached HEAD state detected. Check out a release branch (release-x.y.z) and retry."
    exit 1
fi

if [[ "${CURRENT_BRANCH}" != release-* ]]; then
    echo "ERROR: Release script must be run from a release-* branch. Current branch: ${CURRENT_BRANCH}"
    exit 1
fi

BRANCH_VERSION="${CURRENT_BRANCH#release-}"
if [[ "${BRANCH_VERSION}" != "${RELEASE_VERSION}" ]]; then
    echo "WARNING: Branch name (${CURRENT_BRANCH}) does not match release version (${RELEASE_VERSION})."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting release."
        exit 1
    fi
fi

if ! mvn clean verify; then
    echo "ERROR: Build failed"
    exit 1
fi

# Update versions
echo ""
echo "1. Updating versions to $RELEASE_VERSION..."
cd artagon-bom
mvn versions:set -DnewVersion=$RELEASE_VERSION
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=$RELEASE_VERSION
mvn versions:commit

# Update BOM reference in parent
sed -i.bak "s/<version>.*-SNAPSHOT<\/version>/<version>$RELEASE_VERSION<\/version>/" pom.xml
rm pom.xml.bak

# Update checksums
echo ""
echo "2. Updating checksums..."
cd ../artagon-bom
mvn clean verify
cp security/artagon-bom-checksums.csv ../artagon-parent/security/bom-checksums.csv

# Commit release
echo ""
echo "3. Committing release..."
cd "$PROJECT_ROOT"
git add .
git commit -m "Release version $RELEASE_VERSION"
git tag -a "v$RELEASE_VERSION" -m "Release $RELEASE_VERSION"

# Deploy
echo ""
echo "4. Deploying to OSSRH..."
mvn clean deploy -Possrh-deploy,artagon-oss-release

# Update to next development version
echo ""
echo "5. Updating to next development version $NEXT_VERSION..."
cd artagon-bom
mvn versions:set -DnewVersion=$NEXT_VERSION
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=$NEXT_VERSION
mvn versions:commit

# Update BOM reference
sed -i.bak "s/<version>$RELEASE_VERSION<\/version>/<version>$NEXT_VERSION<\/version>/" pom.xml
rm pom.xml.bak

cd "$PROJECT_ROOT"
git add .
git commit -m "Prepare for next development iteration"

echo ""
echo "=========================================="
echo "Release $RELEASE_VERSION Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Push to remote: git push origin ${CURRENT_BRANCH} --tags"
echo "2. Open a pull request from ${CURRENT_BRANCH} back to main to land post-release commits"
echo "3. Release staging repo at: https://s01.oss.sonatype.org/"
echo "4. Create GitHub release for tag v$RELEASE_VERSION"
echo ""
echo "To rollback if needed:"
echo "  git reset --hard HEAD~2"
echo "  git tag -d v$RELEASE_VERSION"
