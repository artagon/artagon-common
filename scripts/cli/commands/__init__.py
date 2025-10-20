"""
Namespace package for Artagon CLI sub-commands.

Each module under this package is responsible for registering its own
commands with the global registry on import.
"""

from . import java  # noqa: F401  (triggers command registration)
