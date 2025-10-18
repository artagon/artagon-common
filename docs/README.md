# Artagon Documentation

Comprehensive documentation for deploying and releasing Artagon projects.

## Quick Start

### 🚀 I Want to Release Right Now!
**→ [QUICK-RELEASE.md](QUICK-RELEASE.md)** - Fastest way to release to GitHub Packages

### 📦 I Want to Use Artagon Packages
**→ [GITHUB-PACKAGES.md](GITHUB-PACKAGES.md)** - How to consume packages from GitHub

### ⚡ Quick Deployment Reference
**→ [QUICKSTART-DEPLOY.md](QUICKSTART-DEPLOY.md)** - One-page deployment cheat sheet

---

## Complete Guides

### 📖 Full Release Process
**→ [RELEASE-GUIDE.md](RELEASE-GUIDE.md)**

Complete guide covering:
- GitHub Packages releases
- Maven Central releases
- Version management
- GitHub Actions workflows
- Troubleshooting
- Release checklist

### 🚢 Maven Central Deployment
**→ [DEPLOYMENT.md](DEPLOYMENT.md)**

Comprehensive deployment guide:
- OSSRH setup and configuration
- GPG key generation and signing
- Maven settings configuration
- Snapshot and release deployments
- Nexus staging repository
- CI/CD integration

### 🔒 Security & Dependency Verification
**→ [SECURITY-SCRIPTS.md](SECURITY-SCRIPTS.md)**

Security scripts documentation:
- `update-dependency-security.sh` - Generate security baselines
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

---

## Documentation Structure

```
docs/
├── README.md                     # This file - documentation index
├── QUICK-RELEASE.md              # Quick release reference
├── RELEASE-GUIDE.md              # Complete release process
├── GITHUB-PACKAGES.md            # Using GitHub Maven Packages
├── DEPLOYMENT.md                 # Maven Central deployment
├── QUICKSTART-DEPLOY.md          # Quick deployment reference
├── SECURITY-SCRIPTS.md           # Security scripts documentation
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
- **java-build.yml** - Build and test Java projects
- **maven-deploy.yml** - Deploy to Maven repositories
- **maven-release.yml** - Automated release process
- **security-scan.yml** - Security vulnerability scanning

---

## By Use Case

### I'm a Developer Using Artagon Packages

1. [GITHUB-PACKAGES.md](GITHUB-PACKAGES.md) - Setup and configuration
2. Check package versions:
   - https://github.com/artagon/artagon-bom/packages
   - https://github.com/artagon/artagon-parent/packages

### I'm a Maintainer Releasing Artagon

1. [QUICK-RELEASE.md](QUICK-RELEASE.md) - Quick release via GitHub UI
2. [RELEASE-GUIDE.md](RELEASE-GUIDE.md) - Full release process
3. [DEPLOYMENT.md](DEPLOYMENT.md) - Maven Central deployment

### I'm Setting Up a New Artagon Project

1. [QUICKSTART-DEPLOY.md](QUICKSTART-DEPLOY.md) - Quick setup reference
2. [licensing/IMPLEMENTATION-GUIDE.md](licensing/IMPLEMENTATION-GUIDE.md) - License setup
3. [SECURITY-SCRIPTS.md](SECURITY-SCRIPTS.md) - Security baseline setup
4. Copy workflows from `../.github/workflows/examples/`
5. Configure GitHub secrets (see [DEPLOYMENT.md](DEPLOYMENT.md))

### I'm Managing Dependency Security

1. [SECURITY-SCRIPTS.md](SECURITY-SCRIPTS.md) - Security scripts guide
2. Update baselines: `./scripts/update-dependency-security.sh --update`
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
- See [RELEASE-GUIDE.md](RELEASE-GUIDE.md) for version management details
