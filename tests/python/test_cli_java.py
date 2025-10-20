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
    result = run_cli("java", "release", "run", "--version", "1.2.3")
    assert result.returncode == 0
    assert "PLAN" in result.stdout
    assert "1.2.3" in result.stdout


def test_snapshot_publish_dry_run():
    result = run_cli("java", "snapshot", "publish")
    assert result.returncode == 0
    assert "deploy-snapshot.sh" in result.stdout


def test_security_update_dry_run():
    result = run_cli("java", "security", "update")
    assert result.returncode == 0
    assert "security/mvn-update-dep-security.sh --update" in result.stdout


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
