# Artagon Common – Codex Context

## Overview
Shared Artagon infrastructure repository providing language templates, scripts, and automation used across company projects.

### Key Components
- `configs/`: Authoritative source for language templates (Java, C, C++, Rust) including Bazel/CMake scaffolding and formatting configs.
- `nix/templates/`: Reusable Nix flakes with language-specific development shells; documentation lives beside each template.
- `scripts/`: Automation for repo setup, CI helpers, release tooling, security scripts, etc. `setup-repo.sh` bootstraps new projects using the templates.
- `.agents/`: House agent-specific preferences/context (Claude, Codex). Ensure Codex context stays aligned with current repository state.

## Workflows
- **New Project Bootstrapping**: Run `scripts/setup-repo.sh` to create repo structure, add submodules (`.common/artagon-common`, `.legal/artagon-license`), copy templates from `configs/`, optionally add Nix support, and generate docs.
- **Nix Development Environments**: Use `nix/templates/<lang>/flake.nix` for reproducible shells (multiple JDK versions, CI shells, etc.). Conditional checks avoid failures unless project-specific files exist.
- **Documentation Sync**: Any template/script change should update `README.md`, `docs/`, and helper scripts to avoid drift across Artagon projects.

## Maintenance Notes
- Scripts must reference `configs/` (legacy `templates/` path is deprecated).
- Validate bootstrap scripts by creating throwaway repos to ensure copied assets exist.
- When modifying Nix flakes or language templates, update corresponding READMEs and note changes here.
- Keep Git hooks (`git-hooks/`) and licensing automation working with the artagon-license submodule export process.

## Pitfalls / Reminders
- Multi-agent preferences (Claude, Codex) must be kept consistent; update both when policies change.
- Conditional logic in flakes should avoid referencing files that don’t exist in the template itself.
- Ensure scripts fail fast when required submodules or templates are missing to aid user troubleshooting.
