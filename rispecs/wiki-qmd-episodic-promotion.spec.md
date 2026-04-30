# Wiki, QMD, and Episodic Promotion Layer - RISE Specification

> How coaia-agent turns completed sessions, rispecs, and QMD-enriched inquiry into a
> durable wiki-facing knowledge layer without collapsing provenance, specification,
> explanation, retrieval, and episodic memory into one undifferentiated store.

**Version**: 0.1.0
**Document ID**: wiki-qmd-episodic-promotion-v1
**Last Updated**: 2026-04-30
**Status**: Draft
**Related issue**: #13
**Cross-references**:
- [`README.md`](./README.md) - RISE pack index
- [`03-specify.md`](./03-specify.md) - integration architecture and phases
- [`contradictions.md`](./contradictions.md) - human-gated decisions that wiki pages must preserve
- [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md) - future skill/runtime substrate
- `/workspace/wikis/Miadi` - example promoted wiki layer
- `/workspace/repos/jgwill/miadi-orchestration-kit/copilot/miadi-promotion-context-kit` - promotion kit precedent

---

## Desired Outcome

coaia-agent has a durable explanatory wiki at `/workspace/wikis/coaia-agent` that can be
read by humans, queried by QMD, and maintained by future skills, subagents, or plugins.
The wiki is not a raw dump of rispecs. It is a promoted layer that explains the runtime,
COAIA integration path, artifact lifecycle, governance posture, and roadmap in concise,
cross-linked pages.

The same layer also defines how completed work moves from a live session into stable
knowledge:

```
session / issue / commit / PDE artifact
  -> provenance record
  -> rispec or spec update
  -> wiki-facing explanation
  -> QMD-searchable retrieval surface
  -> episodic recall input for later sessions
```

---

## Structural Tension

**Current Reality**

- `coaia-agent/rispecs/` now contains a complete initial RISE spec pack, but it is
  implementation-facing and too dense to be the main orientation surface.
- `/workspace/wikis/coaia-agent` exists, but it only contains the default starter page.
- The Miadi wiki demonstrates the desired explanatory shape: compact pages, cross-links,
  and explicit separation between provenance, spec, wiki, and retrieval.
- The deep-search wave on Karpathy's LLM Wiki pattern argues for a persistent markdown
  knowledge layer with ingest, query, lint, and promotion discipline.
- QMD is available as a remote indexed library across wikis, Miadi docs, IAIP artifacts,
  llms-txt, and rispecs. It can fail on semantic query expansion under VRAM pressure, so
  lexical search must remain a valid fallback path.

**Desired Outcome**

coaia-agent maintains a promoted wiki layer that can be updated incrementally after RISE
sessions. QMD is used to retrieve and enrich context, but the wiki and rispec layers remain
the authored sources of durable explanation and specification.

**Tension**

The project needs memory that is more stable than raw session traces but less binding than
implementation specs. If the wiki copies rispecs wholesale, it becomes unusable. If QMD
retrieval is treated as authority, it hides provenance and human decision gates. If episodic
records are not promoted, later sessions repeat the same orientation work.

---

## 1. Layer Model

coaia-agent adopts the same knowledge layer distinction demonstrated by the Miadi wiki:

| Layer | Role | coaia-agent examples |
| --- | --- | --- |
| Provenance | Origin and traceability | session logs, issue threads, commits, PDE folders, QMD result snippets |
| Spec / rispec | Intended behavior and boundaries | `rispecs/*.spec.md`, contradiction ledger, package contracts |
| Wiki | Concise explanation and navigation | `/workspace/wikis/coaia-agent/*.md` |
| Retrieval | Access and context composition | QMD collections, context assembly, future search tools |
| Episodic | Later-session continuity | promotion logs, session summaries, issue/commit memory, STC lineage |

The wiki layer must not pretend to replace the rispec layer. It points to rispecs where
binding detail is needed and keeps pages short enough to be useful as an orientation web.

---

## 2. Promotion Chain

The promotion chain for coaia-agent is:

```
Provenance -> Rispec/Spec -> Wiki -> Retrieval -> Episodic Recall
```

### 2.1 Provenance

Source material includes:

- issue bodies and comments
- commits and commit messages
- `.pde/<timestamp>--<uuid>/` artifacts
- `.coaia/pde/<uuid>.jsonl` STC sessions
- QMD search results and retrieved source paths
- operator instructions and human-gated decisions

Provenance remains traceable. It is not copied blindly into wiki pages.

### 2.2 Rispec / Spec

Rispecs hold the binding or semi-binding structure:

- package boundaries
- lifecycle contracts
- governance posture
- optional integration contracts
- unresolved contradictions

Wiki drafts should cite these specs rather than duplicate their full content.

### 2.3 Wiki

Wiki pages translate stable material into explanatory pages:

- What this concept is
- Why it matters to coaia-agent
- Which layer owns the binding detail
- Related pages and rispecs
- What remains outside the wiki on purpose

The wiki must be link-rich, not long-form exhaustive.

### 2.4 Retrieval

QMD indexes the wiki and adjacent markdown collections so later sessions can find the
right page, rispec, or provenance artifact. QMD is a retrieval substrate. It is not the
only routing ontology and does not decide what is true.

### 2.5 Episodic Recall

Promotion events should become recallable by future sessions:

- what was promoted
- from which sources
- into which page or rispec
- what was deferred
- what contradiction or human decision remains open

The initial wiki may encode this in page text. A future implementation may add an
append-only promotion log.

---

## 3. Candidate Implementation Surfaces

This spec intentionally does not force one implementation form. The layer may be realized
through one or more of these surfaces:

| Surface | When appropriate | Notes |
| --- | --- | --- |
| Skill | Human invokes `/wiki-promote`, `/qmd-promote`, or `/wiki-lint` in a session | Good first implementation path; matches profile-local skill model |
| Subagent | A bounded worker drafts wiki pages or checks cross-links | Useful for large promotion waves; must preserve source citations |
| Plugin | Lifecycle hook records promotion metadata after session close | Useful after the core lifecycle plugin exists |
| MCP/QMD bridge | Runtime queries QMD or local wiki index for enrichment | QMD remains search/enrichment, not final authority |
| Manual process | Human-curated wiki update following this contract | Valid for the first wiki creation wave |

The first implementation wave for this spec is manual wiki creation. Automation follows
after the wiki shape is visible.

---

## 4. QMD Operating Rules

QMD use in coaia-agent follows these rules:

1. Use QMD to find prior wiki pages, rispecs, and artifacts before drafting new pages.
2. Prefer lexical search when semantic expansion or reranking is unavailable.
3. Store source paths in promotion notes or page source sections.
4. Do not treat QMD snippets as sufficient evidence for a binding claim.
5. If QMD result context conflicts with rispecs or the contradiction ledger, preserve the
   contradiction and route it to human review.

The observed remote failure mode from this session is acceptable: semantic query expansion
can fail due to VRAM constraints. The fallback path is `whispering_inquiry.sh search` with
targeted lexical terms.

---

## 5. Wiki Page Contract

Every coaia-agent wiki page should be:

- concise
- cross-linked
- explanatory rather than exhaustive
- clear about its layer boundary
- explicit about source rispecs or issue references
- careful not to resolve human-gated contradictions silently

Recommended sections:

1. `What this is`
2. `Why it matters`
3. `How it relates to coaia-agent`
4. `Related pages`
5. `Source rispecs`
6. `What stays outside this page`

Not every page needs every section, but each page should keep the same editorial posture.

---

## 6. Initial Wiki Scope

The first `/workspace/wikis/coaia-agent` wave should create pages for:

| Page | Purpose |
| --- | --- |
| `Home.md` | Entry point and reading path |
| `Knowledge-Layers.md` | Provenance/spec/wiki/retrieval/episodic distinction |
| `RISE-Integration.md` | What the RISE spec pack enables |
| `PDE-to-STC-Lifecycle.md` | Prompt -> PDE -> STC -> visualizer artifact path |
| `Package-and-Adapter-Boundaries.md` | Required packages, optional packages, direction/source adapters |
| `Skills-and-Lifecycle-Plugin.md` | Manual skills now, plugin automation later |
| `Governance-and-Contradictions.md` | Human-gated decisions and accountability boundaries |
| `Wiki-QMD-and-Episodic-Promotion.md` | This promotion layer in wiki-facing form |
| `Roadmap.md` | Phase 0/1 core path and Phase 2+ extensions |

The wiki should initially point to local rispec paths and GitHub issues. A later pass can
replace local paths with public URLs if a stable publishing convention is chosen.

---

## 7. Promotion Record Contract

Each promotion wave should record:

```markdown
## Promotion Record

- Source issue(s):
- Source commit(s):
- Source rispec(s):
- QMD queries used:
- Pages created or changed:
- Deferred material:
- Human-gated decisions preserved:
```

This may live in a dedicated `Promotion-Log.md` page or in commit messages until a more
formal episodic store is implemented.

---

## 8. Non-Goals

- This spec does not require a new plugin before the wiki exists.
- This spec does not define QMD as the routing ontology for all inquiry work.
- This spec does not replace `rispecs/` with wiki pages.
- This spec does not import raw deep-search artifacts directly into the wiki.
- This spec does not resolve runtime identity, direction casing, Veritas defaults, or
  Medicine Wheel authority decisions.

---

## 9. Acceptance Criteria

- [ ] `/workspace/wikis/coaia-agent` contains a concise, cross-linked wiki page web
- [ ] The wiki distinguishes provenance, rispec/spec, wiki, retrieval, and episodic layers
- [ ] Pages cite or point to relevant `rispecs/` files and GitHub issues
- [ ] QMD is documented as search/enrichment substrate, not final authority
- [ ] The first wiki wave includes a page explaining wiki/QMD/episodic promotion
- [ ] Human-gated contradictions remain visible and unresolved unless explicitly decided
- [ ] Future automation can implement this layer as skills, subagents, plugins, or MCP/QMD bridges without changing the promotion contract
