# Artagon Common - Claude Agent Context

## Project Overview

**artagon-common** is a shared resource repository providing reusable scripts, documentation, and workflows for all Artagon JVM projects. It is consumed as a git submodule at `.common/artagon-common/` in dependent projects.

**Key Purpose:**
- Centralize security verification scripts
- Maintain single source of truth for generic documentation
- Provide reusable GitHub Actions workflows
- Share common licensing materials

## Project Structure

```
artagon-common/
├── .agents/                    # Agent-specific context files
│   ├── claude/                 # Claude Code context
│   └── codex/                  # GitHub Copilot context
├── docs/                       # Generic documentation
│   ├── README.md              # Documentation index
│   ├── SECURITY-SCRIPTS.md    # Security scripts guide
│   ├── RELEASE-GUIDE.md       # Release process
│   ├── DEPLOYMENT.md          # Maven Central deployment
│   ├── GITHUB-PACKAGES.md     # GitHub Packages usage
│   ├── QUICK-RELEASE.md       # Quick release reference
│   ├── QUICKSTART-DEPLOY.md   # Deployment cheat sheet
│   └── licensing/             # Licensing materials
│       ├── IMPLEMENTATION-GUIDE.md
│       ├── README-LICENSE-SECTION.md
│       └── SOURCE-FILE-HEADER.txt
├── scripts/                    # Shared scripts
│   └── security/              # Security verification scripts
│       ├── update-dependency-security.sh
│       ├── verify-checksums.sh
│       └── generate-dependency-checksums.sh
├── .github/                    # Reusable workflows
│   └── workflows/
└── licenses/                   # License texts
```

## Security Scripts

### update-dependency-security.sh

**Purpose:** Generate security baseline files for Maven dependencies

**Key Features:**
- Auto-detects Maven coordinates (groupId:artifactId)
- Generates SHA-256 checksums for all compile-scope dependencies
- Extracts PGP fingerprints from signatures
- Creates `.sha256` and `.sha512` checksums for baseline files themselves
- Uses Maven coordinate-based file naming

**File Naming Pattern:**
```
{groupId}-{artifactId}-dependency-checksums.csv
{groupId}-{artifactId}-pgp-trusted-keys.list
```

**Common Commands:**
```bash
# Update baselines
./scripts/security/update-dependency-security.sh --update

# Verify baselines
./scripts/security/update-dependency-security.sh --verify
```

### verify-checksums.sh

**Purpose:** Verify SHA-256 and SHA-512 checksums for security baseline files

**Key Features:**
- Verifies integrity of security files before using them
- Colored output (red/green/yellow/blue)
- Multiple file support in single invocation
- Fails fast on mismatch

**Usage Pattern:**
```bash
verify-checksums.sh --security-dir /path/to/security file1.csv file2.list
```

**Critical Implementation Detail:**
- Uses `verified=$((verified + 1))` instead of `((verified++))` to avoid premature exit with `set -e`

## Submodule Usage Pattern

Projects consume artagon-common as a submodule:

```bash
# Initialize submodule
git submodule add https://github.com/artagon/artagon-common.git .common/artagon-common

# Update submodule
cd .common/artagon-common
git pull origin main
cd ../..
git add .common/artagon-common
git commit -m "Update artagon-common submodule"
```

**Wrapper Script Pattern:**

Projects create wrapper scripts that delegate to artagon-common:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_SCRIPT="${PROJECT_ROOT}/.common/artagon-common/scripts/security/update-dependency-security.sh"

if [[ ! -x "${COMMON_SCRIPT}" ]]; then
    echo "ERROR: Shared script not found at ${COMMON_SCRIPT}" >&2
    echo "Ensure artagon-common submodule is initialized:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

exec "${COMMON_SCRIPT}" --project-root "${PROJECT_ROOT}" "$@"
```

## Documentation Organization

### Philosophy
- **DRY Principle:** Generic documentation lives only in artagon-common
- **Single Source of Truth:** Projects reference common docs via relative paths
- **Clear Separation:** Project-specific docs stay in project repos

### Documentation Types

**Generic (in artagon-common):**
- Security scripts guide
- Release process
- Deployment to Maven Central
- GitHub Packages usage
- Licensing implementation
- Quick reference guides

**Project-Specific (in project repos):**
- CHANGELOG.md
- Project-specific release notes
- security/README.md

### Reference Pattern

Projects add Documentation section to README.md:

```markdown
## Documentation

### Common Documentation

General-purpose documentation is maintained in artagon-common:

- **[Security Scripts Guide](.common/artagon-common/docs/SECURITY-SCRIPTS.md)**
- **[Release Guide](.common/artagon-common/docs/RELEASE-GUIDE.md)**
- **[Complete Documentation Index](.common/artagon-common/docs/README.md)**

### Project-Specific Guides

- **[CHANGELOG.md](CHANGELOG.md)**
- **[security/README.md](security/README.md)**
```

## Maven Integration

Projects integrate security scripts via Maven plugins:

### exec-maven-plugin for Checksum Verification

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>verify-security-file-checksums</id>
            <phase>validate</phase>
            <goals>
                <goal>exec</goal>
            </goals>
            <configuration>
                <executable>${project.basedir}/.common/artagon-common/scripts/security/verify-checksums.sh</executable>
                <arguments>
                    <argument>--security-dir</argument>
                    <argument>${project.basedir}/security</argument>
                    <argument>com.artagon-artagon-parent-dependency-checksums.csv</argument>
                    <argument>com.artagon-artagon-parent-pgp-trusted-keys.list</argument>
                </arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```

## Security Workflow

### Initial Setup
1. Initialize submodule: `git submodule update --init --recursive`
2. Generate baselines: `./scripts/update-dependency-security.sh --update`
3. Commit: `git add security/ && git commit`

### Dependency Updates
1. Update pom.xml
2. Regenerate: `./scripts/update-dependency-security.sh --update`
3. Review: `git diff security/`
4. Commit: `git add security/ && git commit`

### Release Process
1. Verify: `./scripts/update-dependency-security.sh --verify`
2. Security build: `mvn -P artagon-oss-security verify`
3. Release build: `mvn -P artagon-oss-release,artagon-oss-security clean verify`

## Coding Conventions

### Bash Scripts

**Strict Mode:**
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Color Output:**
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}SUCCESS: $1${NC}"; }
```

**Arithmetic with set -e:**
```bash
# WRONG - exits when counter is 0
((counter++))

# CORRECT - safe with set -e
counter=$((counter + 1))
```

**Argument Parsing:**
```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done
```

## Common Tasks

### Update Submodule in All Projects

```bash
# In artagon-parent
cd .common/artagon-common
git pull origin main
cd ../..
git add .common/artagon-common
git commit -m "Update artagon-common submodule"

# Repeat for artagon-bom, etc.
```

### Add New Security Script

1. Create in `scripts/security/`
2. Make executable: `chmod +x scripts/security/new-script.sh`
3. Document in `docs/SECURITY-SCRIPTS.md`
4. Update `docs/README.md` if needed
5. Commit and push to artagon-common
6. Update submodules in dependent projects

### Add New Documentation

1. Create in appropriate `docs/` subdirectory
2. Add to `docs/README.md` index
3. Link from relevant sections
4. Commit and push

## Important Considerations

### When Working with artagon-common:

1. **This is a shared resource** - changes affect all projects
2. **Test thoroughly** - broken scripts break all projects
3. **Document everything** - these scripts must be self-documenting
4. **Maintain backwards compatibility** - don't break existing integrations
5. **Version control** - all changes must be committed
6. **Keep it generic** - project-specific logic doesn't belong here

### File Naming Conventions:

- **Scripts:** `kebab-case.sh`
- **Documentation:** `UPPERCASE-WITH-DASHES.md`
- **Directories:** `lowercase`
- **Security files:** `{groupId}-{artifactId}-{type}.{ext}`

### Security Considerations:

- Scripts run during Maven build (trusted context)
- Never modify security baselines manually
- Always use `--verify` before releases
- Review all baseline diffs carefully
- Use version control for all security files

## Integration Points

### Projects Using artagon-common:

1. **artagon-parent** - Parent POM with security profiles
2. **artagon-bom** - Bill of Materials with dependency management
3. Future projects as they're added

### Submodule Path:**
```
.common/artagon-common/
```

### Common Reference Patterns:**

**Documentation:**
```markdown
[Security Scripts Guide](.common/artagon-common/docs/SECURITY-SCRIPTS.md)
```

**Scripts:**
```bash
${project.basedir}/.common/artagon-common/scripts/security/verify-checksums.sh
```

**Workflows:**
```yaml
uses: artagon/artagon-common/.github/workflows/maven-deploy.yml@main
```

## Quick Reference

### Most Common Commands

```bash
# Update security baselines
./scripts/update-dependency-security.sh --update

# Verify security baselines
./scripts/update-dependency-security.sh --verify

# Initialize submodule
git submodule update --init --recursive

# Update submodule to latest
cd .common/artagon-common && git pull origin main && cd ../..
```

### Key Files to Know

- `scripts/security/update-dependency-security.sh` - Baseline generator
- `scripts/security/verify-checksums.sh` - Checksum verifier
- `docs/SECURITY-SCRIPTS.md` - Complete security scripts documentation
- `docs/README.md` - Documentation index
- `docs/licensing/` - Licensing materials

## When Making Changes

1. **Test locally** in a dependent project
2. **Update documentation** if behavior changes
3. **Commit with clear message** explaining the change
4. **Update submodules** in dependent projects
5. **Test again** after submodule update
6. **Document in dependent project commits** why submodule was updated
