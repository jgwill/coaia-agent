# coaia-agent RISE Spec Pack

> **Status**: Spec-only milestone — no runtime code has been modified.  
> **Session UUID**: 2604291305-coaia-agent-rispecs  
> **PDE UUID**: 4da3f9f5-4fe4-4b92-9e9f-f4fead872780  
> **Authored**: NORTH lane N1, claude-sonnet-4.6 (approved fallback for claude-opus-4.6)  
> **Date**: 2026-04-29

This folder contains the foundational RISE specification pack for integrating `coaia-agent`
(currently Hermes 0.11.0) into the COAIA ecosystem as a Hermes-derived runtime. It is
intended to make the integration **implementable by a separate team that did not attend
the authoring session**.

`rispecs/` did not exist before this session. All files here are original authoring.

---

## Scope Statement

This pack covers the zero-core-edit integration path from Hermes runtime surfaces into
COAIA artifact flows (PDE → STC JSONL → coaia-visualizer). It does **not** make a runtime
identity rebrand decision (Hermes → COAIA) — that decision remains with human stewards.
Component-level specs and the contradictions ledger are authored by sibling lanes and are
referenced, not duplicated, here.

---

## Reading Order

| Step | File | Role |
|------|------|------|
| 1 | **[README.md](./README.md)** ← you are here | Pack index and scope |
| 2 | **[00-source-survey.md](./00-source-survey.md)** | Repos surveyed, contribution, required vs optional |
| 3 | **[01-reverse-engineer.md](./01-reverse-engineer.md)** | Hermes runtime surfaces → COAIA integration surfaces |
| 4 | **[02-intent.md](./02-intent.md)** | Desired outcome, current reality, natural resolution, non-goals |
| 5 | **[03-specify.md](./03-specify.md)** | Integration architecture overview; pointers to component specs |
| 6 | **[04-export.md](./04-export.md)** | Handoff sequence, install/run/export, validation notes |
| 7 | **[install-and-first-demo.spec.md](./install-and-first-demo.spec.md)** | Narrow first-demo path with commands and expected artifacts |

**Component specs and contradictions** (authored by other lanes — read after the above):

| File | Authored by | Content |
|------|-------------|---------|
| `coaia-package-consumption.spec.md` | NORTH lane N2 | Package dependency, toolset registration, MCP config |
| `pde-stc-session-lifecycle.spec.md` | NORTH lane N3 | PDE → STC JSONL lifecycle and three input paths |
| `skill-and-plugin-authoring.spec.md` | NORTH lane N4 | RISE skills and lifecycle plugin authoring guide |
| `visualizer-planning-narrative-flow.spec.md` | NORTH lane N5 | JSONL metadata for visualizer compatibility |
| `github-project-runtime-memory-consumption.spec.md` | Hermes follow-on, 2026-05-09 | Runtime contract for canonical `metadata.github`, GitHub Project field projection, and visualizer/accountability alignment |
| `260521-iris-miadi-agent-skill-lineage-integration.rispec.md` | Iris/Hermes follow-on, 2026-05-21 | Strategic bridge from issue-linked Iris skill evolution into Miadi-Agent recommendation issues and Coaia runtime planning lanes |
| `acp-and-gateway-surfaces.spec.md` | NORTH lane N6 | ACP editor adapter and dashboard integration |
| `medicine-wheel-governance.spec.md` | NORTH lane N7 | Ceremony phase annotation, OCAP, consent lifecycle |
| `veritas-mmot-companion.spec.md` | NORTH lane N8 | Optional Veritas STC companion and MMOT loop |
| `wiki-qmd-episodic-promotion.spec.md` | WEST/NORTH bridge | Wiki, QMD, and memory maturation layer |
| `contradictions.md` | WEST lane W1 | Named contradictions ledger; do not silently resolve |
| `relation-to-mcp-structural-thinking.kin.md` | WEST lane W2 | Kinship hub relation (required in all rispecs folders) |

---

## Grounding Facts

- `coaia-agent` is currently **Hermes 0.11.0**, authored by Nous Research, unmodified from
  the upstream fork. No COAIA branding, config paths, or documentation exist yet.
- The zero-core-edit integration path uses `HERMES_HOME=~/.coaia-agent` profile isolation,
  MCP config blocks, RISE skills, a COAIA skin, and lifecycle plugins — all additive.
- The first useful demo path is: prompt → PDE folder artifact → STC JSONL →
  coaia-visualizer load → session summary. Veritas is optional.
- Implementation decisions gated to human authority (including the rebrand decision) are
  named in `contradictions.md` and `02-intent.md`. This pack does not resolve them.

---

## STC Provenance

The Structural Tension Chart for this session:
- STC JSONL: `/a/src/.coaia/pde/48b47ec4-6244-46ae-955b-3724a1b4e071.jsonl`
- PDE Markdown: `/a/src/.pde/2604291317--4da3f9f5-4fe4-4b92-9e9f-f4fead872780/pde-4da3f9f5-4fe4-4b92-9e9f-f4fead872780.md`
- SOUTH findings: `/a/src/.pde/2604291305-coaia-agent-rispecs/deep-search/`
- Rispecs survey: `/a/src/.pde/2604291305-coaia-agent-rispecs/rispecs-survey.md`
