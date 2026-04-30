# Skill and Plugin Authoring — RISE Specification

**Version**: 0.1.0
**Document ID**: skill-and-plugin-authoring-v1
**Last Updated**: 2026-04-29
**Status**: Draft
**Cross-references**: [`01-reverse-engineer.md`](./01-reverse-engineer.md), [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md), [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md), [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md)
**Upstream**: `coaia-agent` (Hermes-derived runtime) — provides skill discovery, slash-command injection, and lifecycle hooks

---

## Desired Outcome

An implementation team can author COAIA-specific skills and a lifecycle plugin for
`coaia-agent` without modifying Hermes core files. The authored surfaces extend the runtime
through profile-local skill packs, plugin hooks, and additive configuration so the COAIA
artifact chain becomes reproducible and maintainable.

---

## Creative Intent / Structural Tension

**Current Reality**: Hermes already exposes two extension planes — skill markdown under
`HERMES_HOME/skills/` and lifecycle hooks via `hermes_cli/plugins.py` — but `coaia-agent`
does not yet describe how to use them for PDE/STC ceremony work.

**Desired Outcome**: COAIA skills and a lifecycle plugin form a stable authoring contract:
skills shape intentional session behavior, the plugin writes and finalizes artifacts, and
both remain additive so upstream Hermes updates can continue to flow.

**Tension**: The runtime is extensible today, but the extension pattern is still implicit.
This spec makes the authoring path explicit without escalating it into core-runtime edits.

---

## Skill Authoring Contract

### Skill location

```text
~/.coaia-agent/skills/coaia/
```

Recommended starter files:

| File | Slash command | Purpose |
|---|---|---|
| `rise-pde-session.md` | `/coaia-rise` | Full RISE PDE ceremony |
| `pde-decompose.md` | `/pde` | Decompose current prompt via `mcp-pde` |
| `stc-create.md` | `/stc` | Create or refresh STC from decomposition |
| `session-summary.md` | `/summary` | Write session close summary |

### Skill frontmatter

```yaml
---
name: rise-pde-session
description: "Full RISE PDE session ceremony via mcp-pde and coaia-pde"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, rise, pde, stc]
    category: coaia
---
```

### Skill authoring rules

1. Skills are injected as **user-message context**, not core system prompt overrides.
2. Skills must refer to canonical package relations:
   - `mcp-pde` for decomposition
   - `coaia-pde` for PDE -> STC import/mapping
   - `coaia-narrative` JSONL as the durable entity/relation ledger
3. Skills must preserve human-gated decisions rather than flatten them.
4. Skills may reference optional Veritas and Medicine Wheel surfaces only as opt-in layers.

---

## Lifecycle Plugin Contract

### Plugin location

```text
~/.coaia-agent/plugins/coaia-lifecycle/
```

### Registration shape

```python
def register(ctx):
    ctx.register_hook("on_session_start", coaia_session_start)
    ctx.register_hook("post_tool_call", coaia_capture_context)
    ctx.register_hook("on_session_end", coaia_session_end)
```

### Hook responsibilities

| Hook | Purpose | Required artifact effect |
|---|---|---|
| `on_session_start` | establish session provenance | create `.pde/<timestamp>--<uuid>/meta.json` scaffold |
| `post_tool_call` | accumulate session evidence | capture context needed for current reality and provenance |
| `on_session_end` | finalize STC-facing outputs | write/update `.coaia/pde/<uuid>.jsonl` and `session-summary.md` |

### Main rules

1. The lifecycle plugin **must not modify Hermes core files**.
2. It should use the preferred folder-backed PDE layout from
   [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md).
3. It should preserve provenance links between SessionDB session id, PDE folder, and STC JSONL.
4. If optional integrations are absent, the plugin must degrade gracefully:
   - no Veritas -> skip companion creation
   - no Medicine Wheel governance -> skip annotations/gates
   - no visualizer -> still emit JSONL path for manual consumption

---

## Authoring Sequence

1. Install or draft the four baseline skills.
2. Validate the narrow manual demo from
   [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md).
3. Add the `coaia-lifecycle` plugin only after the manual path is proven.
4. Promote repeated patterns into more reusable skill/library structures only after the
   first implementation wave is stable.

---

## Acceptance Criteria

- [ ] COAIA skills can be discovered from the profile-local skill folder.
- [ ] The first useful demo works without the lifecycle plugin.
- [ ] The lifecycle plugin can later automate artifact writing without requiring Hermes core edits.
- [ ] Skill and plugin behavior preserve human-gated contradictions instead of silently resolving them.
- [ ] Optional integrations are guarded behind explicit configuration.
