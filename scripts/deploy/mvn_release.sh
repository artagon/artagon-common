#!/usr/bin/env bash
set -euo pipefail

# Release Artagon BOM and Parent to Maven Central
#
# IMPORTANT: This script should be run from a release-* branch that has a SNAPSHOT version.
# The script will remove the -SNAPSHOT suffix to create the release version.
#
# Usage: ./artagon-common/scripts/deploy/mvn_release.sh
# Example workflow:
#   1. Ensure main is at next SNAPSHOT (e.g., 1.0.9-SNAPSHOT)
#   2. git checkout -b release-1.0.8 <commit-at-1.0.8-SNAPSHOT>
#   3. ./artagon-common/scripts/deploy/mvn_release.sh
#   4. git push origin release-1.0.8 --tags

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "Artagon Maven Central Release"
echo "=========================================="

cd "$PROJECT_ROOT"

# Pre-flight checks
echo ""
echo "[1/4] Pre-flight checks..."

# Check 1: Clean working directory
if git status --porcelain | grep .; then
    echo "❌ ERROR: Working directory is not clean. Commit or stash changes."
    exit 1
fi
echo "  ✅ Working directory is clean"

# Check 2: On a branch (not detached HEAD)
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "❌ ERROR: Detached HEAD state detected."
    echo "   Check out a release branch (release-x.y.z) and retry."
    exit 1
fi
echo "  ✅ On branch: $CURRENT_BRANCH"

# Check 3: Must be on a release branch
if [[ "${CURRENT_BRANCH}" != release-* ]]; then
    echo "❌ ERROR: Release script must be run from a release-* branch"
    echo "   Current branch: ${CURRENT_BRANCH}"
    echo ""
    echo "To create a release:"
    echo "  1. Ensure main is at next SNAPSHOT (e.g., 1.0.9-SNAPSHOT)"
    echo "  2. git checkout -b release-1.0.8 <commit-at-1.0.8-SNAPSHOT>"
    echo "  3. Run this script from the release branch"
    exit 1
fi
echo "  ✅ On release branch: $CURRENT_BRANCH"

# Check 4: Version must be SNAPSHOT
cd artagon-bom
CURRENT_VERSION="$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null)"
if [[ "$CURRENT_VERSION" != *-SNAPSHOT ]]; then
    echo "❌ ERROR: Version must be SNAPSHOT on release branch"
    echo "   Current version: $CURRENT_VERSION"
    echo ""
    echo "The release process:"
    echo "  1. Release branch starts with SNAPSHOT version (e.g., 1.0.8-SNAPSHOT)"
    echo "  2. This script removes -SNAPSHOT to create release (1.0.8)"
    echo "  3. Release branch stays at 1.0.8 for hotfixes"
    echo "  4. Main branch continues with next SNAPSHOT (1.0.9-SNAPSHOT)"
    exit 1
fi
RELEASE_VERSION="${CURRENT_VERSION%-SNAPSHOT}"
echo "  ✅ Current version: $CURRENT_VERSION"
echo "  ✅ Will release as: $RELEASE_VERSION"

# Check 5: Build succeeds
echo ""
echo "  Building and testing..."
cd "$PROJECT_ROOT"
if ! mvn clean verify -q; then
    echo "❌ ERROR: Build failed"
    exit 1
fi
echo "  ✅ Build successful"

# Update versions
echo ""
echo "[2/4] Removing SNAPSHOT suffix..."
cd artagon-bom
mvn versions:set -DnewVersion="$RELEASE_VERSION" -DgenerateBackupPoms=false
echo "  ✅ artagon-bom: $RELEASE_VERSION"

cd ../artagon-parent
mvn versions:set -DnewVersion="$RELEASE_VERSION" -DgenerateBackupPoms=false
echo "  ✅ artagon-parent: $RELEASE_VERSION"

# Update BOM reference in parent if needed
if grep -q "<version>.*-SNAPSHOT</version>" pom.xml; then
    sed -i.bak "s/<version>.*-SNAPSHOT<\/version>/<version>$RELEASE_VERSION<\/version>/" pom.xml
    rm -f pom.xml.bak
    echo "  ✅ Updated BOM reference in parent"
fi

# Update checksums
echo ""
echo "[3/4] Updating checksums..."
cd ../artagon-bom
mvn clean verify -q
if [ -f security/artagon-bom-checksums.csv ]; then
    cp security/artagon-bom-checksums.csv ../artagon-parent/security/bom-checksums.csv
    echo "  ✅ Checksums updated"
fi

# Commit release
echo ""
echo "[4/4] Creating release commit and tag..."
cd "$PROJECT_ROOT"
git add .
git commit -m "chore: release version $RELEASE_VERSION"
git tag -a "v$RELEASE_VERSION" -m "Release $RELEASE_VERSION"
echo "  ✅ Created commit and tag v$RELEASE_VERSION"

# Deploy
echo ""
echo "Deploying to OSSRH..."
if mvn clean deploy -Possrh-deploy,artagon-oss-release; then
    echo "  ✅ Deployment successful"
else
    echo "  ❌ Deployment failed"
    echo ""
    echo "To rollback:"
    echo "  git reset --hard HEAD~1"
    echo "  git tag -d v$RELEASE_VERSION"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Release $RELEASE_VERSION Complete!"
echo "=========================================="
echo ""
echo "📦 Release branch: $CURRENT_BRANCH"
echo "🏷️  Release tag: v$RELEASE_VERSION"
echo ""
echo "Next steps:"
echo ""
echo "1. Push release branch and tag:"
echo "   git push origin $CURRENT_BRANCH --tags"
echo ""
echo "2. Release staging repository:"
echo "   Visit: https://s01.oss.sonatype.org/"
echo "   Or run: ./scripts/deploy/mvn_release_nexus.sh"
echo ""
echo "3. Create GitHub release:"
echo "   Visit: https://github.com/artagon/<repo>/releases/new?tag=v$RELEASE_VERSION"
echo ""
echo "4. Keep release branch for future hotfixes"
echo "   Branch $CURRENT_BRANCH will remain at version $RELEASE_VERSION"
echo ""
echo "Note: Main branch should already be at next SNAPSHOT version."
echo "      If not, update it manually or use the version bump workflow."
echo ""
echo "To rollback if needed:"
echo "  git reset --hard HEAD~1"
echo "  git tag -d v$RELEASE_VERSION"
