# Nix Templates for Artagon Projects

This directory contains shared Nix templates for creating reproducible development environments across all Artagon projects.

## Available Templates

### Java/Maven Template (`java/`)

Reproducible development environment for Maven-based Java projects.

**Location:** `nix/templates/java/`

**Files:**
- `flake.nix` - Modern Nix flake configuration
- `shell.nix` - Legacy shell.nix for compatibility
- `README.md` - Comprehensive patterns and usage guide

**Provides:**
- Java Development Kit (JDK 17 and 21)
- Maven build tool
- Security tools (GPG, OpenSSL)
- Documentation tools (Pandoc)
- Version control (Git, Git LFS)
- Utilities (curl, jq, yq-go)

**Multiple Development Shells:**
- `default` - JDK 17 + Maven + all tools
- `jdk17` - Explicit JDK 17 environment
- `jdk21` - JDK 21 for testing compatibility
- `ci` - Minimal CI environment

**Usage in Projects:**

```bash
# Option 1: Symlink to template (recommended)
cd your-project
ln -s .common/artagon-common/nix/templates/java nix
nix develop

# Option 2: Copy template files
cd your-project
mkdir nix
cp .common/artagon-common/nix/templates/java/* nix/
# Customize as needed
nix develop

# Option 3: Direct reference
cd your-project
nix develop .common/artagon-common/nix/templates/java
```

## Using Templates

### 1. As Symlink (Recommended)

**Benefits:**
- Automatic updates when artagon-common is updated
- No duplication
- Consistent across all projects

**Setup:**
```bash
cd your-artagon-project

# Ensure submodule is initialized
git submodule update --init --recursive

# Create symlink
ln -s .common/artagon-common/nix/templates/java nix

# Use it
nix develop
```

**Projects using this approach:**
- artagon-parent
- artagon-bom

### 2. As Copy (For Customization)

**Benefits:**
- Can customize for project-specific needs
- Independent of artagon-common updates

**Setup:**
```bash
cd your-artagon-project

# Copy template
mkdir -p nix
cp .common/artagon-common/nix/templates/java/* nix/

# Customize
vim nix/flake.nix

# Use it
nix develop
```

### 3. Direct Reference (Testing)

**Benefits:**
- No files in your project
- Good for quick testing

**Setup:**
```bash
cd your-artagon-project

# Use directly from artagon-common
nix develop .common/artagon-common/nix/templates/java
```

## Template Structure

```
nix/templates/
├── README.md              # This file
└── java/                  # Java/Maven template
    ├── flake.nix         # Nix flake with multiple shells
    ├── shell.nix         # Legacy compatibility
    └── README.md         # Detailed usage and patterns
```

## Customizing Templates

If you copy a template, you can customize:

### Add Project-Specific Tools

```nix
# In flake.nix
buildInputs = with pkgs; [
  jdk17
  maven
  # Add your tools
  postgresql
  redis
  docker-compose
];
```

### Modify Shell Hook

```nix
shellHook = ''
  echo "Welcome to MyProject!"

  # Custom initialization
  export MY_VAR="value"

  # Run project-specific setup
  ./scripts/dev-setup.sh
'';
```

### Change JDK Version

```nix
# Use different default JDK
buildInputs = [ pkgs.jdk21 pkgs.maven ];
JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
```

## Template Maintenance

### Updating Templates

Templates are maintained in `artagon-common`. To update:

```bash
cd artagon-common

# Edit templates
vim nix/templates/java/flake.nix

# Test in a project
cd ../artagon-parent
nix develop

# Commit and push
cd ../artagon-common
git add nix/templates/
git commit -m "Update Java template"
git push

# Update in projects using symlink
cd ../artagon-parent
git submodule update --remote .common/artagon-common
```

### Adding New Templates

To add a new template type:

```bash
cd artagon-common

# Create template directory
mkdir -p nix/templates/your-template-name

# Create flake.nix
cat > nix/templates/your-template-name/flake.nix << 'EOF'
{
  description = "Your template description";
  # ... template configuration
}
EOF

# Document it
cat > nix/templates/your-template-name/README.md << 'EOF'
# Your Template Name

Usage instructions...
EOF

# Update this README
vim nix/templates/README.md

# Commit
git add nix/templates/
git commit -m "Add new Nix template: your-template-name"
```

## Best Practices

### For Template Maintainers

1. **Keep templates generic** - Project-specific customizations should be in project repos
2. **Document thoroughly** - Each template should have comprehensive README
3. **Test across projects** - Ensure templates work in different contexts
4. **Pin versions carefully** - Balance stability with keeping up to date
5. **Provide examples** - Show common customization patterns

### For Template Users

1. **Use symlinks when possible** - Easier to keep up to date
2. **Don't modify symlinked templates** - Create a copy if you need customization
3. **Document customizations** - If you copy and modify, document why
4. **Test after updating** - When updating artagon-common, test your environment
5. **Share improvements** - If you make useful changes, contribute back

## Troubleshooting

### Symlink broken

**Problem:** `nix develop` fails with "No such file or directory"

**Solution:**
```bash
# Check symlink
ls -la nix

# If broken, recreate
rm nix
ln -s .common/artagon-common/nix/templates/java nix

# Ensure submodule is initialized
git submodule update --init --recursive
```

### Template out of date

**Problem:** Want latest template version

**Solution:**
```bash
# Update artagon-common submodule
cd .common/artagon-common
git pull origin main
cd ../..

# If using symlink, already updated!
# If using copy, re-copy
cp .common/artagon-common/nix/templates/java/* nix/
```

### Need project-specific customization

**Problem:** Template doesn't include tool you need

**Solution:**
```bash
# Copy template instead of symlinking
rm nix  # if symlink exists
mkdir nix
cp .common/artagon-common/nix/templates/java/* nix/

# Customize
vim nix/flake.nix

# Document
echo "# Customizations: Added PostgreSQL" >> nix/README.md
```

## References

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [nix-shell reference](https://nixos.org/manual/nix/stable/command-ref/nix-shell.html)
- [nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/)
- [Artagon Common Documentation](../../docs/README.md)
- [Java Template README](java/README.md)
