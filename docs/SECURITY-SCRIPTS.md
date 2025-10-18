# Security Scripts Documentation

This document describes the security scripts available in artagon-common for managing dependency integrity and verification.

## Overview

Artagon projects use multiple security scripts to ensure dependency integrity through checksum verification and PGP signature validation. These scripts are located in `scripts/security/` and are shared across all Artagon projects via the artagon-common submodule.

## Scripts

### 1. update-dependency-security.sh

**Purpose**: Generates or updates security baseline files for Maven dependencies.

**Location**: `scripts/security/update-dependency-security.sh`

**What it does**:
- Resolves all compile-scope dependencies (including transitives) from Maven
- Downloads artifacts and their PGP signatures from Maven Central
- Computes SHA-256 checksums for each artifact
- Extracts PGP fingerprints from signatures
- Generates security baseline files with Maven coordinate-based naming
- Auto-generates SHA-256 and SHA-512 checksums for the baseline files themselves

**Usage**:
```bash
# Update baselines (long form)
./scripts/update-dependency-security.sh --update

# Update baselines (short form)
./scripts/update-dependency-security.sh -u

# Verify baselines are current
./scripts/update-dependency-security.sh --verify
./scripts/update-dependency-security.sh -v

# Show all options
./scripts/update-dependency-security.sh --help
```

**Options**:
- `-p, --project-root PATH` - Path to Maven project root (default: current directory)
- `-s, --security-dir PATH` - Path to security directory (default: <project-root>/security)
- `-f, --checksum-format FMT` - Format for checksums: 'csv' or 'properties' (default: csv)
- `-S, --scopes SCOPES` - Maven scopes to include, comma-separated (default: compile)
- `-t, --transitive BOOL` - Include transitive dependencies: true or false (default: true)
- `-u, --update` - Update mode: regenerate baseline files (default)
- `-v, --verify` - Verify mode: check existing baselines are current
- `-m, --maven-cmd CMD` - Maven command to use (default: mvn)
- `-h, --help` - Show help message

**Generated Files**:

The script auto-detects the project's Maven coordinates (`groupId` and `artifactId`) and generates files with the naming pattern:

- `{groupId}-{artifactId}-dependency-checksums.csv` - SHA-256 checksums (CSV format)
- `{groupId}-{artifactId}-dependency-checksums.properties` - SHA-256 checksums (properties format)
- `{groupId}-{artifactId}-pgp-trusted-keys.list` - Trusted PGP fingerprints
- `*.sha256` - SHA-256 checksum of each baseline file
- `*.sha512` - SHA-512 checksum of each baseline file

Example for `com.artagon:artagon-parent`:
- `com.artagon-artagon-parent-dependency-checksums.csv`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha256`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha512`
- `com.artagon-artagon-parent-pgp-trusted-keys.list`
- `com.artagon-artagon-parent-pgp-trusted-keys.list.sha256`
- `com.artagon-artagon-parent-pgp-trusted-keys.list.sha512`

**When to Run**:
- After adding, removing, or updating dependencies in `pom.xml`
- Before creating a release to ensure baselines are current
- When PGP keys change for existing dependencies

**Exit Codes**:
- `0` - Success
- `1` - Error occurred

### 2. verify-checksums.sh

**Purpose**: Verifies SHA-256 and SHA-512 checksums for security baseline files.

**Location**: `scripts/security/verify-checksums.sh`

**What it does**:
- Reads expected checksums from `.sha256` and `.sha512` files
- Computes actual checksums for the security baseline files
- Compares expected vs actual checksums
- Fails if any checksum doesn't match
- Provides colored output showing verification status

**Usage**:
```bash
# Verify files in current directory
./verify-checksums.sh file1.csv file2.list

# Verify files in specific directory
./verify-checksums.sh --security-dir /path/to/security file1.csv file2.list

# Short option form
./verify-checksums.sh -d /path/to/security file1.csv
```

**Options**:
- `-d, --security-dir PATH` - Path to security directory (default: current directory)
- `-h, --help` - Show help message

**Arguments**:
- One or more filenames to verify (without path, names only)

**Example Output**:
```
Verifying com.artagon-artagon-parent-dependency-checksums.csv checksums...
  SHA-256: OK
  SHA-512: OK
Verifying com.artagon-artagon-parent-pgp-trusted-keys.list checksums...
  SHA-256: OK
  SHA-512: OK
SUCCESS: Verified 4 checksum(s) successfully
```

**When to Run**:
- Automatically during Maven build (via exec-maven-plugin)
- Before using security baseline files for dependency verification
- As part of CI/CD integrity checks

**Exit Codes**:
- `0` - All checksums verified successfully
- `1` - Checksum verification failed or error occurred

### 3. generate-dependency-checksums.sh

**Purpose**: Standalone script to generate dependency checksums without PGP verification.

**Location**: `scripts/security/generate-dependency-checksums.sh`

**What it does**:
- Similar to `update-dependency-security.sh` but focuses only on checksums
- Generates CSV or properties files with SHA-256 checksums
- Lighter-weight alternative when PGP verification isn't needed

**Usage**:
```bash
# Generate checksums
./scripts/generate-dependency-checksums.sh --project-root /path/to/project

# See all options
./scripts/generate-dependency-checksums.sh --help
```

## Integration with Maven

### In pom.xml

#### Dependency Checksum Verification

Uses `checksum-maven-plugin` to verify dependencies against baseline:

```xml
<plugin>
    <groupId>net.nicoulaj.maven.plugins</groupId>
    <artifactId>checksum-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>verify-dependency-checksums</id>
            <phase>verify</phase>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <csvSummaryFile>${project.basedir}/security/com.artagon-artagon-parent-dependency-checksums.csv</csvSummaryFile>
                <scopes>
                    <scope>compile</scope>
                </scopes>
                <transitive>true</transitive>
                <failOnError>true</failOnError>
            </configuration>
        </execution>
    </executions>
</plugin>
```

#### PGP Signature Verification

Uses `pgpverify-maven-plugin` to verify PGP signatures:

```xml
<plugin>
    <groupId>org.simplify4u.plugins</groupId>
    <artifactId>pgpverify-maven-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <keysMapLocation>${project.basedir}/security/com.artagon-artagon-parent-pgp-trusted-keys.list</keysMapLocation>
                <scope>compile</scope>
            </configuration>
        </execution>
    </executions>
</plugin>
```

#### Security File Checksum Verification

Uses `exec-maven-plugin` to verify the security baseline files themselves:

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

### Wrapper Scripts

Projects can create wrapper scripts to delegate to the shared scripts:

**Example**: `artagon-parent/scripts/update-dependency-security.sh`
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

# Forward all arguments to the shared script with project root
exec "${COMMON_SCRIPT}" --project-root "${PROJECT_ROOT}" "$@"
```

## Security Workflow

### Initial Setup

1. **Initialize submodule**:
   ```bash
   git submodule update --init --recursive
   ```

2. **Generate initial security baselines**:
   ```bash
   ./scripts/update-dependency-security.sh --update
   ```

3. **Commit baseline files**:
   ```bash
   git add security/
   git commit -m "Add security baselines for dependencies"
   ```

### Dependency Updates

When updating dependencies:

1. **Update pom.xml** with new dependencies or versions

2. **Regenerate baselines**:
   ```bash
   ./scripts/update-dependency-security.sh --update
   ```

3. **Review changes**:
   ```bash
   git diff security/
   ```

4. **Commit updates**:
   ```bash
   git add security/
   git commit -m "Update dependency security baselines"
   ```

### Release Process

Before creating a release:

1. **Verify baselines are current**:
   ```bash
   ./scripts/update-dependency-security.sh --verify
   ```

2. **Run security profile**:
   ```bash
   mvn -P artagon-oss-security verify
   ```

3. **Run release build**:
   ```bash
   mvn -P artagon-oss-release,artagon-oss-security clean verify
   ```

The build will automatically:
- Verify security baseline files' checksums (validate phase)
- Verify all dependency checksums (verify phase)
- Verify all PGP signatures (verify phase)
- Fail if any verification fails

## File Naming Convention

All security baseline files use the pattern:
```
{groupId}-{artifactId}-{type}.{ext}
```

Where:
- `{groupId}` - Maven groupId (e.g., `com.artagon`)
- `{artifactId}` - Maven artifactId (e.g., `artagon-parent`)
- `{type}` - File type (`dependency-checksums`, `pgp-trusted-keys`)
- `{ext}` - File extension (`csv`, `list`, `properties`)

Examples:
- `com.artagon-artagon-parent-dependency-checksums.csv`
- `com.artagon-artagon-bom-dependency-checksums.csv`
- `com.artagon-artagon-parent-pgp-trusted-keys.list`

Checksum files add `.sha256` or `.sha512` extensions:
- `com.artagon-artagon-parent-dependency-checksums.csv.sha256`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha512`

## Troubleshooting

### Script Not Found

**Error**: `Shared script not found at .common/artagon-common/scripts/security/...`

**Solution**: Initialize the artagon-common submodule:
```bash
git submodule update --init --recursive
```

### Permission Denied

**Error**: `Permission denied: ./scripts/update-dependency-security.sh`

**Solution**: Make script executable:
```bash
chmod +x ./scripts/update-dependency-security.sh
```

### Checksum Mismatch

**Error**: `SHA-256 checksum mismatch for file.csv`

**Solution**: The file has been modified. Either:
1. Restore the original file from git
2. Regenerate baselines if the change was intentional

### PGP Key Not Found

**Warning**: `Unable to extract fingerprint from ...`

**Solution**: The artifact's PGP signature is unavailable. This is marked as `noKey` in the trusted keys file and is acceptable for some dependencies.

### Maven Plugin Version Warnings

**Warning**: `'build.plugins.plugin.version' for org.codehaus.mojo:exec-maven-plugin is missing`

**Solution**: Add version to pluginManagement in parent POM or specify directly in plugin configuration.

## Best Practices

1. **Always verify before releasing**: Run `--verify` mode before creating releases
2. **Commit baseline changes separately**: Keep security baseline updates in separate commits from functional changes
3. **Review baseline diffs**: Carefully review any changes to security baselines before committing
4. **Use version control**: Never manually edit generated baseline files
5. **Keep submodules updated**: Regularly update artagon-common submodule to get script fixes
6. **Document exceptions**: If marking dependencies as `noKey`, document why in commit messages
7. **Run security profile in CI**: Include `-P artagon-oss-security` in CI builds

## See Also

- [Maven Checksum Plugin Documentation](https://github.com/nicoulaj/checksum-maven-plugin)
- [PGP Verify Plugin Documentation](https://github.com/s4u/pgpverify-maven-plugin)
- [RELEASE-GUIDE.md](RELEASE-GUIDE.md) - Complete release process guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment to Maven Central
