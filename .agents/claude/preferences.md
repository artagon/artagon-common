# Claude Code Preferences for Artagon Projects

## Git Commit Attribution

**DO NOT** include Claude attribution in git commits.

Specifically:
- ❌ Do NOT add "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
- ❌ Do NOT add "Co-Authored-By: Claude <noreply@anthropic.com>"

All commits should show only the human author only.

## Pull Request Attribution

**DO NOT** include Claude attribution in pull request descriptions.

## Documentation and Script Maintenance

**ALWAYS** review and update documentation and scripts after making changes.

When making any code or configuration changes:
- ✅ Update relevant documentation files (README.md, docs/*.md, etc.)
- ✅ Update affected scripts in scripts/ directory
- ✅ Review related configuration files
- ✅ Check for outdated examples or instructions
- ✅ Ensure consistency across all documentation
- ✅ Update version numbers and dates where applicable

**Areas requiring review on changes:**
- README files (project root, subdirectories)
- Documentation in docs/ directory
- Script files in scripts/ directory
- Configuration templates in configs/ directory
- Nix templates and documentation
- Build configuration files (pom.xml, BUILD.bazel, etc.)

**Workflow:**
1. Make code/config changes
2. Identify affected documentation
3. Update documentation to reflect changes
4. Review scripts for compatibility
5. Test updated scripts and examples
6. Commit documentation updates with code changes

## General Principle

These are professional open source projects. All code contributions should be attributed to human authors only, not AI assistants.

Documentation must be kept accurate and up-to-date with every change to maintain project quality and usability.
