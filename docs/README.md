# Artagon Documentation

Comprehensive documentation for deploying and releasing Artagon projects.

## Quick Start

### 🚀 I Want to Release Right Now!
**→ [MAVEN_RELEASE_GUIDE.md#quick-release-github-packages](MAVEN_RELEASE_GUIDE.md#quick-release-github-packages)** - Fastest way to release to GitHub Packages

### 📦 I Want to Use Artagon Packages
**→ [MAVEN_GITHUB-PACKAGES.md](MAVEN_GITHUB-PACKAGES.md)** - How to consume packages from GitHub

### ⚡ Quick Deployment Reference
**→ [MAVEN_RELEASE_GUIDE.md#quick-start-checklist](MAVEN_RELEASE_GUIDE.md#quick-start-checklist)** - One-page deployment cheat sheet

---

## Complete Guides

### 📖 Full Release Process
**→ [MAVEN_RELEASE_GUIDE.md](MAVEN_RELEASE_GUIDE.md)**

Complete guide covering:
- GitHub Packages releases
- Maven Central releases
- Version management
- GitHub Actions workflows
- Troubleshooting
- Release checklist

### 🚢 Maven Central Deployment
**→ [MAVEN_RELEASE_GUIDE.md#deployment-reference](MAVEN_RELEASE_GUIDE.md#deployment-reference)**

Comprehensive deployment guide:
- OSSRH setup and configuration
- GPG key generation and signing
- Maven settings configuration
- Snapshot and release deployments
- Nexus staging repository
- CI/CD integration

### 🔒 Security & Dependency Verification
**→ [MAVEN_RELEASE_GUIDE.md#security-automation](MAVEN_RELEASE_GUIDE.md#security-automation)**

Security scripts documentation:
- `mvn-update-dep-security.sh` - Generate security baselines
- `verify-checksums.sh` - Verify security file checksums
- Maven plugin integration
- Security workflow and best practices
- Troubleshooting

### 📜 Licensing & Legal
**→ [licensing/IMPLEMENTATION-GUIDE.md](licensing/IMPLEMENTATION-GUIDE.md)**

Dual licensing implementation:
- File structure and repository setup
- Package manager metadata
- Source file headers
- CLA configuration

### 🐚 Nix Development Environments
**→ [../nix/templates/README.md](../nix/templates/README.md)**

Reproducible development environment templates:
- Java/Maven template with JDK 17 and 21
- Security tools integration (GPG, OpenSSL)
- Multiple shell configurations
- Cross-platform compatibility (Linux, macOS)
- Symlink vs copy usage patterns

---

## Documentation Structure

```
docs/
├── README.md                     # This file - documentation index
├── MAVEN_QUICK-RELEASE.md              # Quick release reference
├── MAVEN_RELEASE_GUIDE.md              # Complete release process
├── MAVEN_GITHUB-PACKAGES.md            # Using GitHub Maven Packages
├── MAVEN_DEPLOYMENT.md                 # Maven Central deployment
├── MAVEN_QUICKSTART-DEPLOY.md          # Quick deployment reference
├── MAVEN_SECURITY-SCRIPTS.md           # Security scripts documentation
├── BRANCH-PROTECTION.md          # Branch protection setup
├── BRANCH-PROTECTION-USAGE.md    # Using branch protection scripts
└── licensing/
    ├── IMPLEMENTATION-GUIDE.md   # Dual licensing implementation
    ├── README-LICENSE-SECTION.md # License section template
    └── SOURCE-FILE-HEADER.txt    # Source file header template
```

---

## GitHub Actions Workflows

See [../.github/workflows/README.md](../.github/workflows/README.md) for reusable workflows documentation.

Available workflows:
- **maven_build.yml** - Build and test Java projects
- **maven_deploy.yml** - Deploy to Maven repositories
- **maven_release.yml** - Automated release process
- **maven_security_scan.yml** - Security vulnerability scanning

---

## By Use Case

### I'm a Developer Using Artagon Packages

1. [MAVEN_GITHUB-PACKAGES.md](MAVEN_GITHUB-PACKAGES.md) - Setup and configuration
2. Check package versions:
   - https://github.com/artagon/artagon-bom/packages
   - https://github.com/artagon/artagon-parent/packages

### I'm a Maintainer Releasing Artagon

1. [MAVEN_QUICK-RELEASE.md](MAVEN_QUICK-RELEASE.md) - Quick release via GitHub UI
2. [MAVEN_RELEASE_GUIDE.md](MAVEN_RELEASE_GUIDE.md) - Full release process
3. [MAVEN_DEPLOYMENT.md](MAVEN_DEPLOYMENT.md) - Maven Central deployment

### I'm Setting Up a New Artagon Project

1. [MAVEN_QUICKSTART-DEPLOY.md](MAVEN_QUICKSTART-DEPLOY.md) - Quick setup reference
2. [licensing/IMPLEMENTATION-GUIDE.md](licensing/IMPLEMENTATION-GUIDE.md) - License setup
3. [MAVEN_SECURITY-SCRIPTS.md](MAVEN_SECURITY-SCRIPTS.md) - Security baseline setup
4. Copy workflows from `../.github/workflows/examples/`
5. Configure GitHub secrets (see [MAVEN_DEPLOYMENT.md](MAVEN_DEPLOYMENT.md))

### I'm Managing Dependency Security

1. [MAVEN_SECURITY-SCRIPTS.md](MAVEN_SECURITY-SCRIPTS.md) - Security scripts guide
2. Update baselines: `./scripts/mvn-update-dep-security.sh --update`
3. Verify before release: `mvn -P artagon-oss-security verify`

---

## Repositories

- **artagon-bom**: https://github.com/artagon/artagon-bom
- **artagon-parent**: https://github.com/artagon/artagon-parent
- **artagon-common**: https://github.com/artagon/artagon-common

---

## Support

For issues or questions:
- Open an issue in the respective repository
- Check the troubleshooting sections in each guide
- See GitHub Packages documentation: https://docs.github.com/en/packages

---

## Contributing

To improve documentation:
1. Fork artagon-common
2. Update docs in `docs/` directory
3. Submit a pull request

---

## Version Information

- **artagon-bom**: Semantic versioning (MAJOR.MINOR.PATCH)
- **artagon-parent**: Integer versioning (1, 2, 3...)
- See [MAVEN_RELEASE_GUIDE.md](MAVEN_RELEASE_GUIDE.md) for version management details
