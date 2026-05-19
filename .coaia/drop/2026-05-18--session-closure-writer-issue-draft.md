# Issue Draft: Session-Closure Writer + Visualizer/Schema Bridge

Draft only — not created on GitHub.

## Title

Add guarded COAIA session-closure writer and Asterion/visualizer schema bridge

## Repository

`jgwill/coaia-agent`

## Background

The canonical COAIA runtime chart is `/src/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl`, currently centered on `chart_1778353216690`. tmux52 established Coaia-Agent as the owner lane and the first upgrade telescoped action 1 and action 3 into concrete subcharts.

A metadata-loss risk was observed: MCP/tooling can rewrite JSONL into a flatter style and drop rich `metadata.narrative`, `fourDirections`, source refs, GitHub metadata, or narrative beat fields.

The first guard now exists:

`/src/coaia-agent/scripts/validate-coaia-memory.py`

## Desired outcome

Meaningful Coaia-Agent/tmux/Hermes lanes can close into structured narrative memory safely: current-reality observations, narrative beats, telescope candidates, source refs, and optional GitHub/project metadata are written without flattening the canonical JSONL chart.

## Scope

- Add a session-closure writer that appends/updates JSONL while preserving rich metadata.
- Run `scripts/validate-coaia-memory.py` before and after chart writes.
- Define a small adapter shape for COAIA JSONL -> Asterion projection helpers (`Tension`, `ActionStep`, `NarrativeBeat`, `Project`, `AsterionEvent`).
- Add a visualizer/schema bridge only as far as needed to read the canonical JSONL safely.
- Keep writes scoped to `jgwill/coaia-agent` / `/src/coaia-agent`.

## Non-goals

- No Docker rebuild/restart in this issue.
- No `/src/Miadi` changes.
- No GitHub Project mutation until the chart schema names exact `metadata.github` ownership.
- No replacement of `coaia-agent-memory.jsonl` as chart authority.

## Acceptance criteria

- A session closure can produce one current-reality observation and/or one narrative beat with source refs.
- Existing metadata-rich records retain `metadata.narrative`, `metadata.fourDirections`, and other protected metadata after writer runs.
- `./scripts/validate-coaia-memory.py .coaia/narrative/coaia-agent-memory.jsonl` exits `0` after writer operations.
- A small documented mapping exists from canonical JSONL records to Asterion projection concepts.
- A dry-run mode shows intended JSONL changes without writing.

## Evidence / related artifacts

- `.coaia/drop/2026-05-18--coaia-agent-structural-tension-owner-plan.md`
- `.coaia/drop/2026-05-18--coaia-agent-chart-upgrade-1.md`
- `.coaia/drop/2026-05-18--coaia-agent-jsonl-validator-1.md`
- `.coaia/narrative/coaia-agent-memory.jsonl`
