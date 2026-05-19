# COAIA Visualizer MCP release handoff

Date: 2026-05-13 04:00 EDT
Publisher: Hermes/Iris nightly release job

## Published

- `coaia-visualizer-mcp@1.6.0`
- Registry verification: `npm view coaia-visualizer-mcp version` => `1.6.0`
- Service pairing target: `coaia-visualizer@1.6.0`
- Runtime-memory context checked against: `coaia-narrative@0.13.0`

## Config implication for coaia-agent

Prefer published-package MCP config:

```yaml
mcp_servers:
  coaia_visualizer:
    command: "npx"
    args: ["-y", "coaia-visualizer-mcp"]
    env:
      COAIAN_API_TOKEN: "<visualizer token>"
      COAIAV_API_URL: "http://localhost:3000"
```

## What changed in the release package

- fixed package version alignment to `1.6.0`
- added executable shebang for the published bin
- upgraded MCP SDK dependency to the current 1.x line used for release validation
- tightened npm tarball contents to published runtime files only
- updated README examples to show `npx` / Hermes-native MCP usage instead of only local `dist/index.js`
- added compatibility note that the `coaia-github` custom-fields bridge is separate context, not a bundled tool surface in this package

## Compatibility notes

- This package is compatible with the visualizer-side runtime-memory flow.
- The `rispecs/coaia-github` custom-fields / GitHub Projects bridge was explicitly reviewed as context.
- No extra package needed publication tonight:
  - `coaia-narrative` registry already shows `0.13.0`
  - bridge materials remain spec/bridge context rather than a missing runtime package required for this release

## Verification highlights

- `npm run build`
- `npm test --if-present`
- `npm publish --dry-run`
- installed-bin smoke:
  - exits correctly without `COAIAN_API_TOKEN`
  - stays up with fake token + dummy URL, confirming package startup surface is healthy

## GitHub trail

A nightly publication report issue should reference this release branch/commit once pushed from the worktree.
