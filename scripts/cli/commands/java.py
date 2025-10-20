"""
Java-specific commands for the Artagon CLI.

The current implementation focuses on providing a robust, extensible structure
using advanced Python features (dataclasses, enums, functional pipelines) so
it can easily absorb the legacy shell behaviours in subsequent iterations.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from enum import Enum, auto
from typing import Sequence

from ..core import CommandContext, registry, pipeline, step


class ReleaseAction(Enum):
    RUN = auto()
    TAG = auto()
    BRANCH_CUT = auto()
    BRANCH_STAGE = auto()


@dataclass
class ReleaseOptions:
    action: ReleaseAction
    version: str | None = None
    deploy: bool = False


@dataclass
class SnapshotOptions:
    publish: bool = True


@dataclass
class SecurityOptions:
    update: bool = False
    verify: bool = False


def ensure_repository_clean() -> PipelineFn[None]:
    def _inner(ctx: CommandContext) -> None:
        result = ctx.run(["git", "status", "--porcelain"], capture_output=True)
        if result.stdout.strip():
            raise RuntimeError("Working tree is not clean. Commit or stash changes.")

    return _inner


def infer_version_from_branch(ctx: CommandContext) -> str | None:
    """Infer release version from branch naming convention release-x.y.z."""
    result = ctx.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True)
    branch = result.stdout.strip()
    if branch.startswith("release-"):
        return branch.removeprefix("release-")
    return None


def log_release_plan(options: ReleaseOptions) -> PipelineFn[None]:
    def _inner(ctx: CommandContext) -> None:
        print(f"[PLAN] Java release action={options.action.name}, version={options.version}, deploy={options.deploy}")

    return _inner


def execute_release(options: ReleaseOptions) -> PipelineFn[None]:
    """Invoke the legacy release pipeline until full migration is complete."""

    def _inner(ctx: CommandContext) -> None:
        match options.action:
            case ReleaseAction.RUN:
                if not options.version:
                    inferred = infer_version_from_branch(ctx)
                    if not inferred:
                        raise RuntimeError("Unable to infer release version. Provide --version.")
                    options.version = inferred
                ctx.run(["bash", str(ctx.cwd / "scripts/deploy/release.sh"), options.version])
            case ReleaseAction.TAG:
                if not options.version:
                    raise RuntimeError("Version is required for tagging.")
                ctx.run(["git", "tag", f"v{options.version}"])
                ctx.run(["git", "push", "origin", f"v{options.version}"])
            case ReleaseAction.BRANCH_CUT:
                if not options.version:
                    raise RuntimeError("Version required to cut release branch.")
                branch_name = f"release-{options.version}"
                ctx.run(["git", "fetch", "origin", "main"])
                ctx.run(["git", "checkout", "-b", branch_name, "origin/main"])
                ctx.run(["git", "push", "--set-upstream", "origin", branch_name])
            case ReleaseAction.BRANCH_STAGE:
                ctx.run(["bash", str(ctx.cwd / "scripts/deploy/check-deploy-ready.sh")])
                if options.deploy:
                    ctx.run(["bash", str(ctx.cwd / "scripts/deploy/deploy-snapshot.sh")])

    return _inner


def _parse_release_args(args: Sequence[str]) -> ReleaseOptions:
    parser = argparse.ArgumentParser(prog="artagon java release", description="Java release management.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    run_parser = subparsers.add_parser("run", help="Execute the full release pipeline for the current branch.")
    run_parser.add_argument("--version", help="Explicit release version (defaults to inferred value).")

    tag_parser = subparsers.add_parser("tag", help="Create and publish a release tag.")
    tag_parser.add_argument("version", help="Version string to tag (e.g. 1.2.3).")

    branch_parser = subparsers.add_parser("branch", help="Operations on release branches.")
    branch_sub = branch_parser.add_subparsers(dest="branch_cmd", required=True)

    cut_parser = branch_sub.add_parser("cut", help="Create a release branch from main.")
    cut_parser.add_argument("version", help="Version encoded in the release branch name.")

    stage_parser = branch_sub.add_parser("stage", help="Validate a release branch and optionally deploy to staging.")
    stage_parser.add_argument("--deploy", action="store_true", help="Deploy artefacts to staging after validation.")

    parsed = parser.parse_args(list(args))
    if parsed.command == "run":
        return ReleaseOptions(action=ReleaseAction.RUN, version=parsed.version)
    if parsed.command == "tag":
        return ReleaseOptions(action=ReleaseAction.TAG, version=parsed.version)
    if parsed.command == "branch" and parsed.branch_cmd == "cut":
        return ReleaseOptions(action=ReleaseAction.BRANCH_CUT, version=parsed.version)
    if parsed.command == "branch" and parsed.branch_cmd == "stage":
        return ReleaseOptions(action=ReleaseAction.BRANCH_STAGE, deploy=parsed.deploy)
    raise ValueError("Unhandled release command")


@registry.command("java release", "Manage Java release workflows.")
def handle_release(ctx: CommandContext, args: Sequence[str]) -> int:
    options = _parse_release_args(args)
    try:
        pipeline(
            ensure_repository_clean(),
            log_release_plan(options),
            execute_release(options),
        )(ctx)
        return 0
    except RuntimeError as err:
        print(f"Error: {err}")
        return 1


def _parse_snapshot_args(args: Sequence[str]) -> SnapshotOptions:
    parser = argparse.ArgumentParser(prog="artagon java snapshot", description="Java SNAPSHOT management.")
    parser.add_argument("command", choices=["publish"], help="Snapshot action to perform.")
    parser.parse_args(list(args))
    return SnapshotOptions(publish=True)


@registry.command("java snapshot", "Publish Java SNAPSHOT builds.")
def handle_snapshot(ctx: CommandContext, args: Sequence[str]) -> int:
    _ = _parse_snapshot_args(args)
    ctx.run(["bash", str(ctx.cwd / "scripts/deploy/deploy-snapshot.sh")])
    return 0


def _parse_security_args(args: Sequence[str]) -> SecurityOptions:
    parser = argparse.ArgumentParser(prog="artagon java security", description="Java dependency security helpers.")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("update", help="Regenerate dependency security baselines.")
    sub.add_parser("verify", help="Verify dependency security baselines.")
    parsed = parser.parse_args(list(args))
    return SecurityOptions(update=parsed.command == "update", verify=parsed.command == "verify")


@registry.command("java security", "Maintain Java dependency security baselines.")
def handle_security(ctx: CommandContext, args: Sequence[str]) -> int:
    options = _parse_security_args(args)
    if options.update:
        ctx.run(["bash", str(ctx.cwd / "scripts/security/mvn-update-dep-security.sh"), "--update"])
    elif options.verify:
        ctx.run(["bash", str(ctx.cwd / "scripts/security/mvn-update-dep-security.sh"), "--verify"])
    return 0


def _parse_gh_args(args: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="artagon java gh", description="GitHub automations for Java projects.")
    parser.add_argument("command", choices=["protect"], help="GitHub action to perform.")
    parser.add_argument("--branch", default="main", help="Target branch (default: main).")
    return parser.parse_args(list(args))


@registry.command("java gh", "GitHub automations for Java projects.")
def handle_github(ctx: CommandContext, args: Sequence[str]) -> int:
    parsed = _parse_gh_args(args)
    if parsed.command == "protect":
        repo = ctx.config.repo or ctx.cwd.name
        owner = ctx.config.owner
        ctx.run(
            [
                "bash",
                str(ctx.cwd / "scripts/ci/protect-main-branch-team.sh"),
                "--repo",
                repo,
                *( ["--owner", owner] if owner else [] ),
                "--branch",
                parsed.branch,
                "--force",
            ]
        )
    return 0
