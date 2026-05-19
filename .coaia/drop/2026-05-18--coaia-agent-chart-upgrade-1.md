# COAIA-Agent Chart Upgrade 1

## Upgraded chart ids/entities
- `chart_1778353216690_action_1` -> `chart_1778353216690_action_1_telescope_260518`
- `chart_1778353216690_action_3` -> `chart_1778353216690_action_3_telescope_260518`
- Narrative beat: `chart_1778353216690_beat_260518_owner_upgrade_1`

## What changed in current reality
- tmux52 is the owner lane for Coaia-Agent strategic planning / structural tension stewardship.
- Existing master chart `chart_1778353216690` is reused and upgraded, not superseded.
- Action 1 now has a level-1 subchart for session-closure intake.
- Action 3 now has a level-1 subchart for implementation-trace / narrative-beat capture.
- Metadata-rich JSONL was restored after a Docker/MCP rewrite risk flattened older narrative metadata.

## What remains blocked
- Docker-bound tmux52 stalled on preflight compression for the second upgrade prompt.
- The MCP writer can rewrite JSONL in a lossy style unless guarded.
- GitHub issue/project sync is not yet attached to the canonical chart schema.
- Container rebuild/restart should wait until memory paths and MCP config are backed up.

## Next 3 chart operations
1. Add a small validator that checks JSONL record shape and detects metadata loss before/after MCP writes.
2. Telescope action 4 into a RISE/spec adapter for COAIA JSONL + `metadata.github` -> Asterion projections.
3. Create an issue-backed implementation lane in `jgwill/coaia-agent` for the session-closure writer and visualizer/schema bridge.
