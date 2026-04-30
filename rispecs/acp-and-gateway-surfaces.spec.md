# ACP and Gateway Surfaces — RISE Specification

**Version**: 0.1.0
**Document ID**: acp-and-gateway-surfaces-v1
**Last Updated**: 2026-04-29
**Status**: Draft
**Cross-references**: [`01-reverse-engineer.md`](./01-reverse-engineer.md), [`03-specify.md`](./03-specify.md), [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md), [`medicine-wheel-governance.spec.md`](./medicine-wheel-governance.spec.md)
**Upstream**: `coaia-agent` (Hermes-derived runtime) — provides ACP adapter, gateway command dispatch, webhook delivery, and PTY/dashboard surfaces

---

## Desired Outcome

An implementation team understands how `coaia-agent` may surface COAIA capabilities beyond
the terminal: through ACP/editor integrations, dashboard/PTY access, and gateway-triggered
workflows. These surfaces remain secondary to the terminal-first runtime, but they are
specified clearly enough that later implementation waves can attach without guessing.

---

## Creative Intent / Structural Tension

**Current Reality**: Hermes already exposes ACP, gateway, webhook, and dashboard surfaces,
but the COAIA pack mostly speaks in CLI/session terms. That leaves editor and remote-delivery
surfaces acknowledged but under-specified.

**Desired Outcome**: `coaia-agent` has a documented posture for ACP/editor use, gateway/webhook
delivery, and dashboard access that aligns with the same artifact and governance boundaries
defined for the terminal session flow.

**Tension**: The surfaces already exist mechanically, but their COAIA meaning has not yet been
named. This spec gives them a place in the architecture without making them first-demo
requirements.

---

## Surface Map

| Surface | Existing Hermes capability | COAIA role |
|---|---|---|
| ACP adapter | `acp_adapter/entry.py` | editor-facing entry point for PDE/STC-aware actions |
| Messaging gateway | `gateway/run.py` and platform adapters | remote delivery, webhook/session triggers, lightweight review loops |
| Dashboard / PTY bridge | `hermes_cli/web_server.py`, `pty_bridge.py` | browser access to the same terminal ceremony |
| Webhooks / API triggers | gateway webhook and api-server surfaces | automation entry points for later orchestration waves |

---

## ACP Surface Contract

### Scope for v1

ACP support is **optional** and follows the same artifact contract as terminal sessions.
It should not invent a second PDE/STC workflow.

### Minimum ACP goals

1. Expose the same COAIA-enabled runtime profile to editor clients.
2. Preserve PDE/STC artifact writing into the canonical `.pde/` and `.coaia/pde/` roots.
3. Respect the same governance boundaries described in
   [`medicine-wheel-governance.spec.md`](./medicine-wheel-governance.spec.md).

### Deferred concerns

- Rich editor-native STC visualization
- Inline contradiction dashboards
- Multi-pane governance review UIs

These belong to later waves, not the v1 implementation threshold.

---

## Gateway / Webhook Surface Contract

### Primary role

The gateway is a **delivery and trigger surface**, not a second source of truth.

Potential later uses:

| Use | COAIA function |
|---|---|
| Webhook-triggered PDE session | create or resume a decomposition flow from an external event |
| Delivery of session summary | send final or intermediate summary to a remote channel |
| Review prompts | ask a steward to examine contradictions or governance warnings |

### Rules

1. Gateway-triggered sessions must still write to the same canonical artifact roots.
2. Webhook/API triggers must not bypass human-gated decisions captured in `contradictions.md`.
3. Protected-path or consent-aware operations must surface the same warnings and escalation requirements as terminal sessions.

---

## Dashboard / PTY Posture

The browser/dashboard surface should be treated as a **window into the same terminal-first
runtime**, not as a replacement conversation architecture.

This means:

1. Terminal ceremony remains primary.
2. Dashboard access may render or mirror the ongoing session.
3. New structured side panels may be added later, but they must read from the same artifact chain and not create a parallel state model.

---

## Implementation Path

### Phase 0

No ACP or gateway-specific implementation required for the first useful demo.

### Phase 1

Ensure the terminal/profile-based COAIA runtime works cleanly.

### Phase 2+

Add ACP and gateway integrations only after:

- the PDE/STC lifecycle is stable,
- contradictions are preserved visibly,
- governance boundaries are carried through non-terminal triggers.

---

## Acceptance Criteria

- [ ] ACP/editor access is described as optional and artifact-compatible with terminal sessions.
- [ ] Gateway/webhook use is framed as a trigger/delivery surface, not a parallel truth source.
- [ ] Dashboard posture preserves the terminal-first runtime model.
- [ ] No non-terminal surface is permitted to bypass governance and contradiction boundaries.
