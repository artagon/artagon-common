"""
Core building blocks for the Artagon CLI.

The design goals for this module:
    * Encourage declarative registration of commands via decorators.
    * Share a common execution context (root path, environment) across
      commands without relying on global state.
    * Enable functional style "pipelines" for release flows so we can compose
      reusable, testable steps.
"""

from __future__ import annotations

import functools
import os
import tomllib
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional, Sequence, Tuple, TypeVar


Handler = Callable[["CommandContext", Sequence[str]], int]


@dataclass(frozen=True)
class CLIConfig:
    """Configuration values loaded from .artagonrc."""

    language: str = "java"
    owner: str | None = None
    repo: str | None = None

    @classmethod
    def load(cls, path: Path | None) -> "CLIConfig":
        if path is None or not path.exists():
            return cls()
        try:
            with path.open("rb") as fh:
                data = tomllib.load(fh)
        except OSError as exc:
            raise RuntimeError(f"Failed to read config at {path}: {exc}") from exc

        defaults = data.get("defaults", {}) if isinstance(data, dict) else {}
        return cls(
            language=str(defaults.get("language", "java")),
            owner=defaults.get("owner"),
            repo=defaults.get("repo"),
        )


@dataclass(frozen=True)
class CommandSpec:
    """Metadata describing a CLI command."""

    path: str
    help: str
    handler: Handler


class CommandRegistry:
    """Stores command registrations and exposes a decorator-based API."""

    def __init__(self) -> None:
        self._commands: Dict[str, CommandSpec] = {}

    def register(self, spec: CommandSpec) -> None:
        key = spec.path.strip().lower()
        if key in self._commands:
            raise ValueError(f"Command '{spec.path}' already registered")
        self._commands[key] = spec

    def command(self, path: str, help_text: str) -> Callable[[Handler], Handler]:
        """Decorator used by command modules to register handlers."""

        def decorator(func: Handler) -> Handler:
            self.register(CommandSpec(path=path, help=help_text, handler=func))
            return func

        return decorator

    def find(self, tokens: Iterable[str]) -> Tuple[Optional[CommandSpec], List[str]]:
        """Resolve the longest command path matching the provided tokens."""
        original = list(tokens)
        lowered = [token.lower() for token in original]
        for i in range(len(lowered), 0, -1):
            key = " ".join(lowered[:i])
            if key in self._commands:
                return self._commands[key], original[i:]
        return None, original

    def __iter__(self):
        return iter(self._commands.items())


registry = CommandRegistry()


@dataclass
class CommandContext:
    """
    Shared execution context passed to each command handler.

    Attributes:
        cwd: Repository root (resolved once per invocation).
        env: Process environment variables available to commands.
        dry_run: When true, side-effects should be logged but not executed.
    """

    cwd: Path = field(default_factory=lambda: Path.cwd())
    env: Dict[str, str] = field(default_factory=lambda: dict(os.environ))
    dry_run: bool = False
    config: CLIConfig = field(default_factory=lambda: CLIConfig.load(Path.cwd() / ".artagonrc"))

    def run(
        self,
        command: Sequence[str],
        *,
        check: bool = True,
        capture_output: bool = False,
        text: bool = True,
        cwd: Optional[Path] = None,
        read_only: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        """Execute a subprocess respecting the context configuration."""

        if self.dry_run and not read_only:
            print(f"[dry-run] {' '.join(command)}")
            return subprocess.CompletedProcess(command, 0, "", "")

        return subprocess.run(  # noqa: S603, S607
            list(command),
            cwd=cwd or self.cwd,
            env=self.env,
            check=check,
            capture_output=capture_output,
            text=text,
        )


T = TypeVar("T")
PipelineFn = Callable[[CommandContext], T]


def pipeline(*steps: PipelineFn[Any]) -> PipelineFn[Any]:
    """
    Compose multiple context-aware steps into a single callable.

    Each step receives the shared CommandContext and may return arbitrary data.
    Later steps can be defined using functools.partial to capture previous step
    outputs if needed. The pipeline returns the result of the final step.
    """

    def runner(ctx: CommandContext) -> Any:
        result: Any = None
        for step in steps:
            result = step(ctx)
        return result

    return runner


def step(fn: Callable[..., T]) -> Callable[..., PipelineFn[T]]:
    """
    Decorator that converts a regular function into a pipeline-compatible step.

    The wrapped function automatically receives the CommandContext as the first
    argument, followed by any bound arguments (via functools.partial).
    """

    @functools.wraps(fn)
    def wrapper(*args: Any, **kwargs: Any) -> PipelineFn[T]:
        return functools.partial(fn, *args, **kwargs)

    return wrapper
