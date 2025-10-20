# Agent Directory Symlink Structure

## Overview

The agent configuration has been refactored to eliminate duplication between Claude and Codex agents while maintaining model-specific customizations. This is achieved through a unified directory structure with strategic use of symlinks.

## Directory Structure

```
.agents-shared/              # Canonical shared content
  ├── preferences.md         # Unified workflow preferences
  └── project-context.md     # Project structure and history

.agents-claude/              # Claude-specific configuration
  ├── project.md             # Claude model settings
  ├── preferences.md         -> ../.agents-shared/preferences.md
  └── project-context.md     -> ../.agents-shared/project-context.md

.agents-codex/               # Codex-specific configuration
  ├── project.md             # Codex model settings
  ├── preferences.md         -> ../.agents-shared/preferences.md
  └── project-context.md     -> ../.agents-shared/project-context.md

# Model-facing symlinks (for agent compatibility)
.claude                      -> .agents-claude
.codex                       -> .agents-codex
.agents                      -> .agents-codex (backward compatibility)

# Old structure (preserved for reference)
.agents-old/                 # Original .agents/ directory
  ├── claude/
  │   └── preferences.md
  └── codex/
      ├── preferences.md
      └── project-context.md
```

## How It Works

### Shared Content

All content that is common between Claude and Codex is stored in `.agents-shared/`:
- **preferences.md**: Unified workflow preferences including semantic commits, issue-driven workflow, and quality standards
- **project-context.md**: Project structure, recent changes, and maintenance notes

### Model-Specific Content

Each agent has its own directory (`.agents-claude/`, `.agents-codex/`) containing:
- **project.md**: Model-specific configuration and settings
- **Symlinks** to shared content (preferences.md, project-context.md)

### Agent Compatibility Symlinks

To maintain compatibility with how agents expect to find their configuration:
- `.claude` → `.agents-claude` (for Claude Code)
- `.codex` → `.agents-codex` (for Codex)
- `.agents` → `.agents-codex` (for tools that look for `.agents/`)

## Benefits

1. **Single Source of Truth**: Shared preferences and context are maintained in one location
2. **Easier Maintenance**: Update shared content once, applies to both agents
3. **Clear Separation**: Model-specific vs shared configuration is explicit
4. **Backward Compatible**: Symlinks maintain compatibility with existing tools
5. **No Duplication**: ~80% content overlap eliminated

## Platform Compatibility

### Unix/Linux/macOS

Symbolic links work natively. The structure is already set up and functional.

```bash
# Verify symlinks
ls -la .claude .codex .agents
ls -la .agents-claude/ .agents-codex/
```

### Windows

Windows 10+ supports symlinks but requires special handling:

#### Developer Mode (Recommended)
Enable Developer Mode in Windows Settings to create symlinks without admin rights.

#### Alternative: Directory Junctions
If symlinks aren't available, use junctions:

```powershell
# Create model alias junctions
mklink /J .claude .agents-claude
mklink /J .codex .agents-codex
mklink /J .agents .agents-codex

# Shared content junctions (inside each model directory)
cd .agents-claude
mklink /J preferences.md ..\.agents-shared\preferences.md
mklink /J project-context.md ..\.agents-shared\project-context.md
cd ..

cd .agents-codex
mklink /J preferences.md ..\.agents-shared\preferences.md
mklink /J project-context.md ..\.agents-shared\project-context.md
cd ..
```

**Note**: Junctions work like symlinks but are Windows-specific. Git will track them correctly.

## Migration

### Automated Migration

The migration was performed automatically with:
- Backup created: `tools/migrations/agents-backup-20251020-062846.tar.gz`
- Migration report: `tools/migrations/agents-refactor-*.json`
- Original directory preserved as `.agents-old/`

### Manual Migration (if needed)

If you need to recreate the structure:

```bash
# 1. Create directories
mkdir -p .agents-shared .agents-claude .agents-codex

# 2. Copy shared content
cp .agents-old/codex/project-context.md .agents-shared/
# Merge preferences manually into .agents-shared/preferences.md

# 3. Create model-specific project.md files
# (See .agents-claude/project.md and .agents-codex/project.md)

# 4. Create shared content symlinks
cd .agents-claude
ln -s ../.agents-shared/preferences.md preferences.md
ln -s ../.agents-shared/project-context.md project-context.md
cd ..

cd .agents-codex
ln -s ../.agents-shared/preferences.md preferences.md
ln -s ../.agents-shared/project-context.md project-context.md
cd ..

# 5. Create model alias symlinks
ln -s .agents-claude .claude
ln -s .agents-codex .codex
ln -s .agents-codex .agents
```

## Rollback

If you need to revert to the original structure:

```bash
# Extract backup
tar -xzf tools/migrations/agents-backup-20251020-062846.tar.gz

# Remove new structure
rm -rf .agents-shared .agents-claude .agents-codex

# Remove symlinks
rm .claude .codex .agents

# Restore original
mv .agents-old .agents
```

## Sync Scripts

Two scripts help maintain the structure:

### Claude Sync
```bash
./scripts/gh_sync_claude.sh [--dry-run]
```
Ensures `.claude` symlink points to `.agents-claude`

### Codex Sync
```bash
./scripts/gh_sync_codex.sh [--dry-run]
```
Ensures `.agents` and `.codex` symlinks point to `.agents-codex`

## Verification

Check that everything is working:

```bash
# Verify symlinks exist
ls -la .claude .codex .agents

# Verify symlink targets
readlink .claude .codex .agents

# Test content resolution
head -5 .claude/project.md
head -5 .agents/project.md

# Verify shared content is linked
ls -la .agents-claude/preferences.md
ls -la .agents-codex/preferences.md
```

Expected output shows symlinks (indicated by `->`) pointing to their targets.

## Maintenance

### Updating Shared Content

Edit files in `.agents-shared/` only:
```bash
# Edit shared preferences
vim .agents-shared/preferences.md

# Changes automatically visible to both Claude and Codex
```

### Updating Model-Specific Content

Edit `project.md` in each model directory:
```bash
# Claude-specific settings
vim .agents-claude/project.md

# Codex-specific settings
vim .agents-codex/project.md
```

### Adding New Shared Content

1. Add file to `.agents-shared/`
2. Create symlinks in `.agents-claude/` and `.agents-codex/`
3. Update `context.include` in each `project.md` if needed

## Troubleshooting

### Broken Symlinks

```bash
# Find broken symlinks
find .agents-claude .agents-codex -type l ! -exec test -e {} \; -print

# Recreate if needed
cd .agents-claude
ln -sf ../.agents-shared/preferences.md preferences.md
```

### Agent Can't Find Configuration

1. Verify symlink exists: `ls -la .claude` or `ls -la .agents`
2. Verify symlink target exists: `ls -la .agents-claude` or `ls -la .agents-codex`
3. Run sync script: `./scripts/gh_sync_claude.sh` or `./scripts/gh_sync_codex.sh`

### Windows Symlink Issues

- Enable Developer Mode in Windows Settings
- Or use junctions (mklink /J) instead
- Or use WSL for full Unix compatibility

## See Also

- [Agent Preferences](.agents-shared/preferences.md) - Shared workflow preferences
- [Project Context](.agents-shared/project-context.md) - Project structure and history
- [Contributing Guide](docs/CONTRIBUTING.md) - Development workflow
