"""
Java-specific commands for the Artagon CLI.

Implements release management, snapshot deployments, dependency security
automation, and GitHub branch protection using the shared CLI infrastructure.
"""

from __future__ import annotations

import argparse
import re
import shutil
from dataclasses import dataclass
from enum import Enum, auto
from pathlib import Path
from typing import Sequence

from ..core import CommandContext, registry, pipeline


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
    allow_mismatch: bool = False
    branch: str | None = None
    next_version: str | None = None


@dataclass
class SnapshotOptions:
    publish: bool = True


@dataclass
class SecurityOptions:
    update: bool = False
    verify: bool = False


def ensure_repository_clean() -> callable:
    def _inner(ctx: CommandContext) -> None:
        if ctx.env.get("ARTAGON_SKIP_GIT_CLEAN") == "1":
            return
        result = ctx.run(["git", "status", "--porcelain"], capture_output=True, read_only=True)
        if result.stdout.strip():
            raise RuntimeError("Working tree is not clean. Commit or stash changes.")

    return _inner


def ensure_release_branch(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        result = ctx.run(["git", "symbolic-ref", "--short", "HEAD"], capture_output=True, read_only=True)
        branch = result.stdout.strip()
        if not branch:
            raise RuntimeError("Unable to determine current branch.")
        options.branch = branch

        if options.action in {ReleaseAction.RUN, ReleaseAction.TAG, ReleaseAction.BRANCH_STAGE}:
            if not branch.startswith("release-"):
                if not options.allow_mismatch:
                    raise RuntimeError(
                        f"Release commands must run from a release-* branch. Current: {branch}"
                    )
            else:
                branch_version = branch.removeprefix("release-")
                if options.version is None:
                    options.version = branch_version
                elif options.version != branch_version and not options.allow_mismatch:
                    raise RuntimeError(
                        f"Branch ({branch}) does not match version {options.version}. "
                        "Use --allow-branch-mismatch to override."
                    )

    return _inner


def log_release_plan(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        print(f"[PLAN] Java release action={options.action.name}, version={options.version}, deploy={options.deploy}")

    return _inner


def validate_build() -> callable:
    def _inner(ctx: CommandContext) -> None:
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] validate build")
            return
        ctx.run(["mvn", "clean", "verify"])

    return _inner


def calculate_next_snapshot(version: str) -> str:
    parts = version.split(".")
    if not parts:
        raise ValueError("Invalid version string")
    try:
        parts[-1] = str(int(parts[-1]) + 1)
    except ValueError as exc:
        raise ValueError(f"Unable to increment version component in '{version}'") from exc
    return ".".join(parts) + "-SNAPSHOT"


def update_versions_to_release(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if not options.version:
            raise RuntimeError("Release version is not set.")
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] update versions to release")
            return
        bom_dir = ctx.cwd / "artagon-bom"
        parent_dir = ctx.cwd / "artagon-parent"
        ctx.run(["mvn", "versions:set", f"-DnewVersion={options.version}"], cwd=bom_dir)
        ctx.run(["mvn", "versions:commit"], cwd=bom_dir)
        ctx.run(["mvn", "versions:set", f"-DnewVersion={options.version}"], cwd=parent_dir)
        ctx.run(["mvn", "versions:commit"], cwd=parent_dir)

        parent_pom = parent_dir / "pom.xml"
        text = parent_pom.read_text()
        updated = re.sub(r"<version>.*-SNAPSHOT</version>", f"<version>{options.version}</version>", text, count=1)
        parent_pom.write_text(updated)

    return _inner


def update_checksums(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] update checksums")
            return
        bom_dir = ctx.cwd / "artagon-bom"
        parent_dir = ctx.cwd / "artagon-parent"
        ctx.run(["mvn", "clean", "verify"], cwd=bom_dir)
        src = bom_dir / "security" / "artagon-bom-checksums.csv"
        dest_dir = parent_dir / "security"
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / "bom-checksums.csv"
        shutil.copy2(src, dest)

    return _inner


def commit_release(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if not options.version:
            raise RuntimeError("Release version is not set")
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] commit release")
            return
        ctx.run(["git", "add", "."])
        ctx.run(["git", "commit", "-m", f"Release version {options.version}"])
        ctx.run(["git", "tag", "-a", f"v{options.version}", "-m", f"Release {options.version}"])

    return _inner


def deploy_release() -> callable:
    def _inner(ctx: CommandContext) -> None:
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] deploy release")
            return
        ctx.run(["mvn", "clean", "deploy", "-Possrh-deploy,artagon-oss-release"])

    return _inner


def bump_to_next_snapshot(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if not options.version:
            raise RuntimeError("Release version is not set")
        options.next_version = calculate_next_snapshot(options.version)
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] bump to next snapshot")
            return
        bom_dir = ctx.cwd / "artagon-bom"
        parent_dir = ctx.cwd / "artagon-parent"
        ctx.run(["mvn", "versions:set", f"-DnewVersion={options.next_version}"], cwd=bom_dir)
        ctx.run(["mvn", "versions:commit"], cwd=bom_dir)
        ctx.run(["mvn", "versions:set", f"-DnewVersion={options.next_version}"], cwd=parent_dir)
        ctx.run(["mvn", "versions:commit"], cwd=parent_dir)
        parent_pom = parent_dir / "pom.xml"
        text = parent_pom.read_text()
        updated = re.sub(
            rf"<version>{re.escape(options.version)}</version>",
            f"<version>{options.next_version}</version>",
            text,
            count=1,
        )
        parent_pom.write_text(updated)

    return _inner


def commit_next_iteration(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if ctx.env.get("ARTAGON_SKIP_RELEASE_STEPS") == "1":
            print("[skip] commit next iteration")
            return
        ctx.run(["git", "add", "."])
        ctx.run(["git", "commit", "-m", "Prepare for next development iteration"])

    return _inner


def summarize_release(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        version = options.version or "<unknown>"
        branch = options.branch or "<release-branch>"
        print("==========================================")
        print(f"Release {version} complete!")
        print("==========================================")
        print("Next steps:")
        print(f"1. Push to remote: git push origin {branch} --tags")
        print(f"2. Open a pull request from {branch} back to main")
        print("3. Release staging repo at: https://s01.oss.sonatype.org/")
        print(f"4. Create GitHub release for tag v{version}")
        if options.next_version:
            print(f"Next development version: {options.next_version}")

    return _inner


def create_release_tag(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if not options.version:
            raise RuntimeError("Version is required for tagging.")
        ctx.run(["git", "tag", "-a", f"v{options.version}", "-m", f"Release {options.version}"])
        ctx.run(["git", "push", "origin", f"v{options.version}"])

    return _inner


def create_release_branch(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        if not options.version:
            raise RuntimeError("Version required to cut release branch.")
        branch_name = f"release-{options.version}"
        ctx.run(["git", "fetch", "origin", "main"])
        ctx.run(["git", "checkout", "-b", branch_name, "origin/main"])
        ctx.run(["git", "push", "--set-upstream", "origin", branch_name])
        options.branch = branch_name

    return _inner


def summarize_stage(options: ReleaseOptions) -> callable:
    def _inner(ctx: CommandContext) -> None:
        branch = options.branch or "<release-branch>"
        print(f"Stage validation completed for {branch}.")
        if options.deploy:
            print("Artifacts deployed to OSSRH staging. Review and release when ready.")
        else:
            print("Run with --deploy to publish staging artifacts once validation passes.")

    return _inner


def _parse_release_args(args: Sequence[str]) -> ReleaseOptions:
    parser = argparse.ArgumentParser(prog="artagon java release", description="Java release management.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    run_parser = subparsers.add_parser("run", help="Execute the full release pipeline for the current branch.")
    run_parser.add_argument("--version", help="Explicit release version (defaults to branch inference).")
    run_parser.add_argument(
        "--allow-branch-mismatch",
        action="store_true",
        help="Allow release version to differ from release-* branch name.",
    )

    tag_parser = subparsers.add_parser("tag", help="Create and publish a release tag.")
    tag_parser.add_argument("version", help="Version string to tag (e.g. 1.2.3).")

    branch_parser = subparsers.add_parser("branch", help="Operations on release branches.")
    branch_sub = branch_parser.add_subparsers(dest="branch_cmd", required=True)

    cut_parser = branch_sub.add_parser("cut", help="Create a release branch from main.")
    cut_parser.add_argument("version", help="Version encoded in the release branch name.")

    stage_parser = branch_sub.add_parser("stage", help="Validate a release branch and optionally deploy to staging.")
    stage_parser.add_argument("--deploy", action="store_true", help="Deploy artefacts to staging after validation.")
    stage_parser.add_argument(
        "--allow-branch-mismatch",
        action="store_true",
        help="Allow branch naming mismatch when staging.",
    )

    parsed = parser.parse_args(list(args))
    if parsed.command == "run":
        return ReleaseOptions(
            action=ReleaseAction.RUN,
            version=parsed.version,
            allow_mismatch=parsed.allow_branch_mismatch,
        )
    if parsed.command == "tag":
        return ReleaseOptions(action=ReleaseAction.TAG, version=parsed.version)
    if parsed.command == "branch" and parsed.branch_cmd == "cut":
        return ReleaseOptions(action=ReleaseAction.BRANCH_CUT, version=parsed.version)
    if parsed.command == "branch" and parsed.branch_cmd == "stage":
        return ReleaseOptions(
            action=ReleaseAction.BRANCH_STAGE,
            deploy=parsed.deploy,
            allow_mismatch=parsed.allow_branch_mismatch,
        )
    raise ValueError("Unhandled release command")


@registry.command("java release", "Manage Java release workflows.")
def handle_release(ctx: CommandContext, args: Sequence[str]) -> int:
    options = _parse_release_args(args)
    try:
        steps = [ensure_repository_clean()]
        if options.action not in {ReleaseAction.BRANCH_CUT}:
            steps.append(ensure_release_branch(options))
        steps.append(log_release_plan(options))

        if options.action == ReleaseAction.RUN:
            steps.extend(
                [
                    validate_build(),
                    update_versions_to_release(options),
                    update_checksums(options),
                    commit_release(options),
                    deploy_release(),
                    bump_to_next_snapshot(options),
                    commit_next_iteration(options),
                    summarize_release(options),
                ]
            )
        elif options.action == ReleaseAction.TAG:
            steps.append(create_release_tag(options))
        elif options.action == ReleaseAction.BRANCH_CUT:
            steps.append(create_release_branch(options))
        elif options.action == ReleaseAction.BRANCH_STAGE:
            steps.append(validate_build())
            if options.deploy:
                steps.append(deploy_release())
            steps.append(summarize_stage(options))

        pipeline(*steps)(ctx)
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
    ctx.run(["mvn", "clean", "deploy", "-Possrh-deploy,artagon-oss-release"])
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
    security_script = ctx.cwd / "scripts/security/mvn_update_security.sh"
    if options.update:
        ctx.run(["bash", str(security_script), "--update"])
    elif options.verify:
        ctx.run(["bash", str(security_script), "--verify"])
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
        command = [
            "bash",
            str(ctx.cwd / "scripts/ci/gh_protect_main_team.sh"),
            "--repo",
            repo,
            "--branch",
            parsed.branch,
            "--force",
        ]
        if owner:
            command.extend(["--owner", owner])
        ctx.run(command)
    return 0
