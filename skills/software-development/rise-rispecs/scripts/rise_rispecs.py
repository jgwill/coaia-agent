#!/usr/bin/env python3
"""First-draft RISE/rispec helper tooling.

Commands:
  init       Create a starter ./rispecs tree without overwriting existing files.
  staleness  Compare rispec mtimes with git commits and changed files.
  validate  Check rispecs for required RISE sections and anti-pattern language.

This script intentionally stays dependency-free so it can run in any checkout.
"""
from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable

REQUIRED_SECTIONS = [
    "Desired Outcome Definition",
    "Current Reality",
    "Structural Tension",
    "Natural Progression",
    "Functional Specification",
    "Validation",
]

ANTI_PATTERNS = {
    r"\bfix(?:es|ed|ing)?\b": "Prefer outcome framing over reactive fixing language.",
    r"\beliminat(?:e|es|ed|ing)\b": "Describe what the system enables, not what it removes.",
    r"\bbridg(?:e|es|ed|ing) the gap\b": "Avoid forced-connection framing.",
    r"\busers must\b": "Use natural progression rather than force-based language.",
    r"\brequires determination\b": "Structural tension should not depend on willpower.",
    r"Current Structural Reality": "Use the exact heading/phrase 'Current Reality'.",
    r"Desired Structural State": "Use 'Desired Outcome' or 'Desired State'.",
}

DEFAULT_SPECS = {
    "app.spec.md": "Application Rispec Map",
    "agent-loop.spec.md": "Agent Loop",
    "tools.spec.md": "Tools and Toolsets",
    "skills.spec.md": "Skills and Procedural Memory",
    "delegation.spec.md": "Delegation and Subagents",
    "cron.spec.md": "Scheduled Jobs",
    "memory.spec.md": "Memory and Session Recall",
    "gateway.spec.md": "Gateway and Messaging Surfaces",
    "cli-tui.spec.md": "CLI, TUI, and Dashboard Surfaces",
    "data-models.spec.md": "Data Models and Persistence",
    "validation.spec.md": "RISE Validation Gates",
}


def run_git(args: list[str], cwd: Path) -> str:
    result = subprocess.run(
        ["git", *args], cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result.stdout.strip()


def repo_root(start: Path) -> Path:
    try:
        return Path(run_git(["rev-parse", "--show-toplevel"], start)).resolve()
    except Exception:
        return start.resolve()


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def spec_template(title: str) -> str:
    return f"""# {title}

This rispec describes what this capability enables users or agents to create.

## Desired Outcome Definition

- Desired Outcome: Define the specific result this capability enables.
- Value: Describe why that result matters.
- Completion Signal: Describe how success becomes visible.

## Current Reality

Describe the present state, constraints, user/agent context, and existing
structural conditions.

## Structural Tension

Describe the dynamic relationship between Current Reality and the Desired
Outcome. Explain why the system naturally wants to advance.

## Natural Progression

Explain the advancing pattern that moves the user or agent toward the Desired
Outcome without force-based effort.

## Functional Specification

Describe behavior, data flow, decisions, commands, prompts, events, APIs, UI
surfaces, or persistence rules at the level another LLM needs to implement the
capability adequately.

## Creative Advancement Scenarios

**Creative Advancement Scenario**: First Outcome Path

**User Intent**: The desired outcome they want to create.
**Current Reality**: The starting context.
**Natural Progression Steps**:
  1. A structural dynamic enables the first advance.
  2. The system responds with useful context or capability.
  3. The user or agent advances toward the desired outcome.
**Achieved Outcome**: The manifested result.
**Supporting Features**: Capabilities enabling this advancement.

## Beloved Qualities to Preserve

- Identify qualities that should survive reimplementation.

## Implementation-Sufficient Notes

Add schemas, API contracts, examples, prompts, source provenance, or git commit
references where they preserve implementation intent.

## Validation

- [ ] Creative orientation preserved
- [ ] Structural dynamics explicit
- [ ] Advancing patterns described
- [ ] Anti-pattern language avoided
- [ ] Black-box rebuild ready
"""


def app_template(spec_names: Iterable[str]) -> str:
    spec_lines = "\n".join(f"- `{name}`: See this rispec for its capability boundary." for name in spec_names if name != "app.spec.md")
    return f"""# Application Rispec Map

This file explains how to use the rispec suite as a codebase-agnostic blueprint.

## Desired Outcome Definition

- Desired Outcome: Agents and developers can rebuild, extend, and evaluate this
  application from living specifications rather than source archaeology alone.
- Value: The system's creative intent and beloved qualities remain available as
  implementation evolves.
- Completion Signal: Another LLM can navigate this folder and implement the
  described capabilities adequately without reading the original source.

## Current Reality

The repository contains executable implementation and may contain changing
features, commits, tools, services, and interaction surfaces. Without living
rispecs, design intent can become implicit in code and commit history.

## Structural Tension

The Desired Outcome asks for autonomous, implementation-sufficient prose code.
Current Reality stores much of that intent in executable artifacts. The tension
creates natural movement toward separated specs that preserve creative intent
while still allowing implementation details to evolve.

## Natural Progression

Use this map first, then open the capability-specific rispecs. Each spec states
its Desired Outcome, Current Reality, Structural Tension, Natural Progression,
Functional Specification, scenarios, beloved qualities, and validation gates.

## Functional Specification

The rispec suite is organized as separated capability files:

{spec_lines}

When adding a feature, update the smallest affected rispec and then update this
map if a new capability boundary appears. When maintaining specs, run Phase 4:
compare rispec timestamps to git history, mine commits, map changed files to
specs, update the relevant rispecs, and validate black-box rebuild readiness.

## Creative Advancement Scenarios

**Creative Advancement Scenario**: Rebuild from Prose Code

**User Intent**: Create an implementation that preserves the application's intent.
**Current Reality**: The implementer starts with rispecs rather than source code.
**Natural Progression Steps**:
  1. The map reveals the capability boundaries.
  2. Each capability spec supplies behavior, structures, scenarios, and validation.
  3. The implementer creates code that manifests the same desired outcomes.
**Achieved Outcome**: A coherent reimplementation aligned with the original
creative intent.
**Supporting Features**: Cross-references, implementation-sufficient notes, and
validation gates.

## Beloved Qualities to Preserve

- Specifications remain clear enough for humans and operational enough for LLMs.
- Source provenance supports maintenance without making specs codebase-dependent.
- The suite advances as the implementation advances.

## Implementation-Sufficient Notes

Generated by `rise_rispecs.py init` on {now_iso()}. Replace placeholders with
repository-specific behavior and cite important commits during maintenance.

## Validation

- [ ] Creative orientation preserved
- [ ] Structural dynamics explicit
- [ ] Advancing patterns described
- [ ] Anti-pattern language avoided
- [ ] Black-box rebuild ready
"""


def display_path(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def command_init(args: argparse.Namespace) -> int:
    root = repo_root(Path.cwd())
    rispec_dir = (root / args.rispec_dir).resolve() if not Path(args.rispec_dir).is_absolute() else Path(args.rispec_dir)
    rispec_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    skipped: list[Path] = []
    for filename, title in DEFAULT_SPECS.items():
        path = rispec_dir / filename
        if path.exists() and not args.force:
            skipped.append(path)
            continue
        content = app_template(DEFAULT_SPECS.keys()) if filename == "app.spec.md" else spec_template(title)
        path.write_text(content, encoding="utf-8")
        written.append(path)
    print(f"rispec_dir={rispec_dir}")
    for path in written:
        print(f"created {display_path(path, root)}")
    for path in skipped:
        print(f"skipped_existing {display_path(path, root)}")
    return 0


def latest_mtime(paths: Iterable[Path]) -> float | None:
    times = [p.stat().st_mtime for p in paths if p.is_file()]
    return max(times) if times else None


def command_staleness(args: argparse.Namespace) -> int:
    root = repo_root(Path.cwd())
    rispec_dir = (root / args.rispec_dir).resolve() if not Path(args.rispec_dir).is_absolute() else Path(args.rispec_dir)
    specs = sorted(rispec_dir.glob("*.spec.md")) if rispec_dir.exists() else []
    mtime = latest_mtime(specs)
    print(f"repo={root}")
    print(f"rispec_dir={rispec_dir}")
    print(f"spec_count={len(specs)}")
    if mtime is None:
        print("status=missing_or_empty_rispec_dir")
        return 1 if args.strict else 0
    since = dt.datetime.fromtimestamp(mtime, dt.timezone.utc).isoformat()
    print(f"latest_spec_mtime={since}")
    commits = run_git(["log", f"--since={since}", "--pretty=format:%h|%s|%an|%ar", "--no-merges"], root)
    commit_hashes = run_git(["log", f"--since={since}", "--pretty=format:%H", "--no-merges"], root)
    changed_files: set[str] = set()
    for commit_hash in [line.strip() for line in commit_hashes.splitlines() if line.strip()]:
        names = run_git(["diff-tree", "--no-commit-id", "--name-only", "-r", commit_hash], root)
        changed_files.update(line.strip() for line in names.splitlines() if line.strip())
    changed = "\n".join(sorted(changed_files))
    if commits:
        print("commits_since_latest_spec:")
        for line in commits.splitlines():
            print(f"  {line}")
    else:
        print("commits_since_latest_spec=none")
    if changed:
        print("changed_files_hint:")
        for line in changed.splitlines():
            print(f"  {line}")
    else:
        print("changed_files_hint=none_or_use_git_log_hashes_for_diff")
    return 0


def iter_spec_files(rispec_dir: Path) -> list[Path]:
    return sorted(rispec_dir.glob("*.spec.md"))


def validate_file(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    issues: list[str] = []
    if not text.lstrip().startswith("# "):
        issues.append("missing top-level # title")
    for section in REQUIRED_SECTIONS:
        if not re.search(rf"^##\s+{re.escape(section)}\s*$", text, re.MULTILINE):
            issues.append(f"missing section: {section}")
    if "Creative Advancement Scenario" not in text:
        issues.append("missing Creative Advancement Scenario")
    if "Beloved Qualities" not in text:
        issues.append("missing Beloved Qualities section")
    for pattern, message in ANTI_PATTERNS.items():
        if re.search(pattern, text, re.IGNORECASE):
            issues.append(f"anti-pattern '{pattern}': {message}")
    return issues


def command_validate(args: argparse.Namespace) -> int:
    root = repo_root(Path.cwd())
    rispec_dir = (root / args.rispec_dir).resolve() if not Path(args.rispec_dir).is_absolute() else Path(args.rispec_dir)
    specs = iter_spec_files(rispec_dir) if rispec_dir.exists() else []
    if not specs:
        print(f"FAIL no *.spec.md files in {rispec_dir}")
        return 1
    failures = 0
    for path in specs:
        issues = validate_file(path)
        rel = path.relative_to(root) if path.is_relative_to(root) else path
        if issues:
            failures += 1
            print(f"FAIL {rel}")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print(f"PASS {rel}")
    if failures:
        print(f"summary=FAIL files_with_issues={failures} total={len(specs)}")
        return 1
    print(f"summary=PASS total={len(specs)}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="RISE/rispec helper tooling")
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="create starter rispec files")
    p_init.add_argument("--rispec-dir", default="rispecs")
    p_init.add_argument("--force", action="store_true", help="overwrite existing generated files")
    p_init.set_defaults(func=command_init)

    p_stale = sub.add_parser("staleness", help="show git-log-driven maintenance hints")
    p_stale.add_argument("--rispec-dir", default="rispecs")
    p_stale.add_argument("--strict", action="store_true", help="exit non-zero when rispecs are missing")
    p_stale.set_defaults(func=command_staleness)

    p_validate = sub.add_parser("validate", help="validate rispec markdown files")
    p_validate.add_argument("--rispec-dir", default="rispecs")
    p_validate.set_defaults(func=command_validate)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
