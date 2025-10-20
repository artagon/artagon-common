#!/usr/bin/env python3
"""Generate agent configuration markdown files from a shared manifest."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Mapping


@dataclass(frozen=True)
class AgentSpec:
    name: str
    output: Path
    title: str
    description: str
    heading: str
    inherits_from: str
    context_include: List[str]
    specific_sections: List[Mapping[str, str]]


def load_manifest(manifest_path: Path) -> tuple[Mapping[str, Iterable[str]], list[AgentSpec]]:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))

    shared = data.get("shared", {})
    context_include = list(shared.get("context_include", []))
    snippets = [Path(snippet) for snippet in shared.get("snippets", [])]

    agents: list[AgentSpec] = []
    for name, spec in data.get("agents", {}).items():
        agent_context = spec.get("context_include", context_include)
        agents.append(
            AgentSpec(
                name=name,
                output=Path(spec["output"]),
                title=spec["title"],
                description=spec["description"],
                heading=spec["heading"],
                inherits_from=spec["inherits_from"],
                context_include=list(agent_context),
                specific_sections=list(spec.get("specific_sections", [])),
            )
        )

    return {"snippets": snippets}, agents


def read_snippets(repo_root: Path, snippet_paths: Iterable[Path]) -> str:
    snippets: List[str] = []
    for rel_path in snippet_paths:
        snippet_path = (repo_root / rel_path).resolve()
        if not snippet_path.is_file():
            raise FileNotFoundError(f"Snippet file not found: {rel_path}")
        snippets.append(snippet_path.read_text(encoding="utf-8").strip())
    return "\n\n".join(snippets).strip()


def render_agent(spec: AgentSpec, shared_snippet: str) -> str:
    front_matter_lines = [
        "---",
        f"# {spec.title}",
        f"# {spec.description}",
        "context:",
        "  include:",
    ]
    for entry in spec.context_include:
        front_matter_lines.append(f"    - {entry}")
    front_matter_lines.append(f"inherits_from: \"{spec.inherits_from}\"")
    front_matter_lines.append("---")

    body_parts: List[str] = [f"# {spec.heading}"]
    if shared_snippet:
        body_parts.append("")
        body_parts.append(shared_snippet)

    for section in spec.specific_sections:
        heading = section.get("heading", "").strip()
        body = section.get("body", "").rstrip()
        if not heading or not body:
            continue
        body_parts.append("")
        body_parts.append(f"## {heading}")
        body_parts.append("")
        body_parts.append(body)

    body_text = "\n".join(body_parts).strip()
    content = "\n".join(front_matter_lines).rstrip() + "\n\n" + body_text + "\n"
    return content


def ensure_parent_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def generate_agents(repo_root: Path, manifest_path: Path, write: bool, check: bool) -> int:
    shared, agents = load_manifest(manifest_path)
    shared_snippet = read_snippets(repo_root, shared.get("snippets", []))

    rc = 0
    for agent in agents:
        output_path = (repo_root / agent.output).resolve()
        content = render_agent(agent, shared_snippet)

        if check:
            if not output_path.exists():
                print(f"[agent-config] Missing file: {agent.output}", file=sys.stderr)
                rc = 1
                continue

            existing = output_path.read_text(encoding="utf-8")
            if existing != content:
                print(f"[agent-config] Out of date: {agent.output}", file=sys.stderr)
                rc = 1
        elif write:
            ensure_parent_dir(output_path)
            output_path.write_text(content, encoding="utf-8")
            print(f"[agent-config] Wrote {agent.output}")
        else:
            print(content, end="")

    return rc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate agent project.md files from manifest")
    parser.add_argument(
        "--manifest",
        default=".agents-shared/agent-manifest.json",
        help="Path to manifest JSON file (default: %(default)s)",
    )
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
        "--write",
        action="store_true",
        help="Write generated content to disk",
    )
    action_group.add_argument(
        "--check",
        action="store_true",
        help="Verify existing files match generated output",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    manifest_path = (repo_root / args.manifest).resolve()

    if not manifest_path.is_file():
        print(f"Manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    return generate_agents(repo_root, manifest_path, write=args.write, check=args.check)


if __name__ == "__main__":
    sys.exit(main())
