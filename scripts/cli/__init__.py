"""
Artagon CLI core utilities.

This module exposes the global command registry and helper utilities for
sub-command modules to register their handlers in a declarative fashion.
"""

from .core import CLIConfig, CommandContext, CommandRegistry, registry  # noqa: F401
