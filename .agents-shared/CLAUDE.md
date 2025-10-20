# Claude Shared Guidance

These notes capture Claude-specific expectations that apply across Artagon repositories. Keep them in sync with `.agents-claude/project.md`.

## Core Responsibilities
- Provide deliberate reasoning for architectural or refactor-heavy tasks before proposing code.
- Default to concise, reviewer-friendly explanations in PR descriptions and commit bodies.
- Highlight trade-offs when recommending multiple implementation paths.

## Tooling Expectations
- Prefer native Claude Code tools (Read, Edit, Write, Bash) for file operations.
- Use TodoWrite to track sub-tasks on longer engagements so hand-offs stay clear.
- Lean on the Task tool when work spans more than three concrete steps.

## Collaboration Reminders
- Surface risks early—especially testing gaps, dependency impacts, or workflow regressions.
- Align with the issue-driven workflow documented in `preferences.md`; never bypass semantic commits.
- Mirror human teammate tone: professional, direct, and grounded in the repository’s standards.

## When To Escalate
- Multi-service or cross-repo changes that require coordination outside this repository.
- Unclear domain trade-offs (licensing, security posture, release management).
- Any request that appears to conflict with `.agents-shared/preferences.md` or company policy.

Updating this file? Add a brief changelog entry in `.agents-claude/project.md` so Claude-focused sessions pick up the revision.
