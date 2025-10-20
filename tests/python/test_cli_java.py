from __future__ import annotations

import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "scripts" / "artagon"
ENV = dict(os.environ)
ENV["PYTHONPATH"] = os.pathsep.join(
    filter(None, [str(ROOT / "scripts"), ENV.get("PYTHONPATH")])
)
ENV["ARTAGON_SKIP_GIT_CLEAN"] = "1"
ENV["ARTAGON_SKIP_RELEASE_STEPS"] = "1"


def run_cli(*args: str, dry_run: bool = True) -> subprocess.CompletedProcess[str]:
    command = [str(CLI)]
    if dry_run:
        command.append("--dry-run")
    command.extend(args)
    return subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        env=ENV,
    )


def test_release_run_dry_run():
    result = run_cli(
        "java",
        "release",
        "run",
        "--version",
        "1.2.3",
        "--allow-branch-mismatch",
    )
    assert result.returncode == 0
    assert "PLAN" in result.stdout
    assert "1.2.3" in result.stdout


def test_snapshot_publish_dry_run():
    result = run_cli("java", "snapshot", "publish")
    assert result.returncode == 0
    assert "mvn clean deploy -Possrh-deploy,artagon-oss-release" in result.stdout


def test_security_update_dry_run():
    result = run_cli("java", "security", "update")
    assert result.returncode == 0
    assert "security/mvn_update_security.sh --update" in result.stdout


def test_unknown_command():
    result = subprocess.run(
        [str(CLI), "unknown"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        env=ENV,
    )
    assert result.returncode == 2
    assert "Unknown command path" in result.stderr


def test_github_protect_uses_config_defaults():
    result = run_cli("java", "gh", "protect", "--branch", "main")
    assert result.returncode == 0
    assert "--repo artagon-common" in result.stdout
    assert "--owner artagon" in result.stdout
