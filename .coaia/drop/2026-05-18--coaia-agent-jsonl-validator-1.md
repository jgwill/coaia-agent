# COAIA-Agent JSONL Validator 1

Date: 2026-05-18
Scope: `/src/coaia-agent` only. No Docker rebuild/restart. No `/src/Miadi`.

## What it protects

`/src/coaia-agent/scripts/validate-coaia-memory.py` protects the canonical chart memory at:

`/src/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl`

It checks:

- valid JSONL, one object per nonblank line
- stable unique `name` ids for entity/narrative records
- required entity fields such as `type`, `entityType`, `observations`, and `metadata.chartId` where applicable
- relation endpoints that resolve to known entity names or chart ids
- `metadata.telescopedToChartId` targets that resolve to known chart ids/entities
- baseline-preservation from `HEAD` so existing rich metadata is not accidentally flattened away
- protected metadata paths when they already existed: `metadata.narrative`, `metadata.fourDirections`, `metadata.source_refs`, `metadata.sourceRefs`, `metadata.github`, `metadata.asterion.source_refs`, `metadata.asterion.sourceRefs`
- narrative beat payload preservation: `metadata.narrative.summary`, `metadata.narrative.events`, `metadata.narrative.lessons`, `metadata.fourDirections`

## How to run it

From repo root:

```bash
./scripts/validate-coaia-memory.py .coaia/narrative/coaia-agent-memory.jsonl
```

Shape-only mode, if there is no safe git baseline:

```bash
./scripts/validate-coaia-memory.py .coaia/narrative/coaia-agent-memory.jsonl --no-baseline
```

## Current result

Command run:

```bash
chmod +x scripts/validate-coaia-memory.py && ./scripts/validate-coaia-memory.py .coaia/narrative/coaia-agent-memory.jsonl
```

Result:

```text
COAIA memory validation OK
file: /a/src/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl
records parsed: 40
stable named records: 23
relations: 17
records with protected rich metadata: 3
baseline: HEAD:.coaia/narrative/coaia-agent-memory.jsonl (23 records)
```

Exit code: `0`.

Note: `/a/src/coaia-agent` is the resolved path for the `/src/coaia-agent` worktree in this shell.

## Next 3 chart operations

1. Telescope action 4 into a RISE/spec adapter for COAIA JSONL + `metadata.github` -> Asterion projection helpers.
2. Draft the issue-backed implementation lane for the session-closure writer + visualizer/schema bridge.
3. Add the validator to any future MCP/chart-write workflow before and after JSONL mutation.
