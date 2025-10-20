# Codex Preferences for Artagon Projects

## Attribution
- Do NOT include Codex or other AI attribution in commits or PRs.
- All commits must list the human author only (no "Co-Authored-By" AI metadata).

## Change Hygiene
- Update documentation, scripts, and templates whenever code behaviour changes.
- Keep Nix flakes, language templates, and automation scripts in sync with documentation in `README.md` and `docs/`.
- Prefer small, well-scoped commits with clear intent and context.

## Coding Style
- Follow repository conventions defined in `configs/` and language-specific tooling (formatters, linters, etc.).
- Opt for clarity over clever optimisations; comment only when intent may be non-obvious.

## Tooling Expectations
- Run available formatters/lints/tests relevant to your changes.
- Add or update tests when fixing bugs or changing behaviour.
- Validate `scripts/setup-repo.sh` or other bootstrap scripts using a temporary repo when touched.

## Context Memory
- Record meaningful repository patterns, workflows, or pitfalls in `project-context.md` after significant changes.
- Note structural shifts (new directories, renamed templates, etc.) so future sessions stay aligned.

## Guiding Principle
Treat Artagon repositories as professional, human-run projects. Automation assists delivery, but human accountability, thorough docs, and reproducible workflows take precedence.
