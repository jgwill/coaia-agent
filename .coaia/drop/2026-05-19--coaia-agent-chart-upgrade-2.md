# COAIA-Agent Chart Upgrade 2

## Upgraded chart ids/entities
- `chart_1778353216690_action_4_telescope_260518`
- `chart_1778353216690_action_4_telescope_260518_current_reality`
- `chart_1778353216690_action_4_telescope_260518_action_1`
- `chart_1778353216690_action_4_telescope_260518_action_2`
- `chart_1778353216690_action_4_telescope_260518_action_3`
- `/opt/data/config.yaml` MCP command now references `coaia-narrative@0.13.2`
- Global npm packages now report `coaia-narrative@0.13.2` and `coaia-visualizer@1.6.3`

## Validator result
- `scripts/validate-coaia-memory.py` ran successfully after restoration and upgrade.
- Result: 51 records parsed, 28 stable named records, 23 relations, 5 records with protected rich metadata.
- The validator caught a live MCP flattening event after `update_current_reality`; rich narrative beat metadata was restored before continuing.

## What changed in current reality
- Latest package facts are installed, not only recorded: `coaia-narrative@0.13.2`, `coaia-visualizer@1.6.3`.
- Hermes config now starts `coaia-agent-chart` with `coaia-narrative@0.13.2` against `/workspace/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl`.
- Action 4 now has concrete sub-actions for version/config audit, validator-before/after discipline, and RISE/Asterion projection.
- Upstream implementation stack exists: `avadisabelle/coaia-narrative#35` and `jgwill/coaia-visualizer#20`.

## What remains blocked
- Active MCP session may need reload/restart before it uses the updated config command.
- MCP writer still flattened rich narrative beat metadata during this session; upstream fix remains pending.
- Baseline validation is currently run with `--no-baseline`; a committed or saved pre-write baseline should become standard.

## Next 3 chart operations
1. Reload/restart MCP, then run validator before and after one harmless chart read/write to confirm `coaia-narrative@0.13.2` behavior.
2. Telescope action 1 sub-action 4 into a dedicated metadata-preservation guard lane tied to `avadisabelle/coaia-narrative#35`.
3. Telescope action 2 into a visualizer observation lane tied to `jgwill/coaia-visualizer#20` and verify rich chart/action/beat projections.
