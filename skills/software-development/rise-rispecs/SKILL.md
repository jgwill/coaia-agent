---
name: rise-rispecs
description: Use when creating, maintaining, exporting, or reviewing RISE/rispec specifications that preserve creative intent, structural tension, and implementation-sufficient living documentation.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [rise, rispecs, speclang, specifications, creative-archaeology, living-docs]
    related_skills: [writing-plans, subagent-driven-development, requesting-code-review, hermes-agent-skill-authoring]
---

# RISE/Rispecs

## Overview

RISE transforms code analysis and feature planning into creative archaeology:
reverse-engineer the system, extract intent, specify desired outcomes, and
export implementation-sufficient specifications. A rispec is a markdown
specification that describes what a system enables users or agents to create,
how current reality advances toward desired outcomes, and which structural
dynamics make that progression natural.

Use this skill to create a `./rispecs/` folder, generate first-draft specs,
maintain them from git history, and review them for black-box rebuild readiness.
The specification is treated as prose code: it is maintained as a source of
truth while executable code remains one implementation of that intent.

## When to Use

Use this skill when the user asks for:

- RISE framework application, RISE specs, or `rispecs`
- creative archaeology, intent extraction, or SpecLang-style prose code
- living specs that evolve with git commits
- codebase-agnostic blueprints another LLM could rebuild from
- review of specs for creative orientation, structural tension, or anti-patterns
- generation of `./rispecs/app.spec.md` and feature/service/component specs

Do not use this skill for ordinary code comments, reactive bug summaries, or
architecture docs that only describe current implementation without desired
outcomes.

## Core Vocabulary

| Term | Meaning |
| --- | --- |
| Desired Outcome | The specific result the user, developer, or agent wants to create. |
| Current Reality | The present state of the user, system, repo, or workflow. Use exactly this phrase. |
| Structural Tension | The dynamic relationship between Current Reality and Desired Outcome. |
| Natural Progression | How the system advances toward the desired outcome without forced effort. |
| Advancing Pattern | A relationship that compounds movement toward the desired outcome. |
| Oscillating Pattern | A loop that creates back-and-forth effort without advancement. |
| Beloved Quality | A capability, behavior, or feel worth preserving through reimplementation. |
| Creative Advancement Scenario | A scenario format that replaces reactive BDD stories. |

Important wording constraints:

- Use `Current Reality`, not `Current Structural Reality`.
- Use `Desired Outcome` or `Desired State`, not inflated phrases like `Desired Structural State`.
- Prefer `enables`, `creates`, `advances`, `supports`, `manifests`.
- Avoid `fixes`, `eliminates`, `bridges the gap`, `users must`, `requires determination`.

## Rispec Folder Shape

Create a `./rispecs/` directory with separated markdown files by capability,
surface, component, service, or feature. A practical first draft for an agent
codebase is:

```text
rispecs/
  app.spec.md                 # map of all specs and how to use them
  agent-loop.spec.md          # conversation loop, tool calling, compression
  tools.spec.md               # tool registry, toolsets, schemas, side effects
  skills.spec.md              # skill loading, authoring, lifecycle, curator
  delegation.spec.md          # subagents, review loops, orchestration
  cron.spec.md                # scheduled/durable jobs
  memory.spec.md              # persistent memory and session recall
  gateway.spec.md             # messaging platforms and delivery surfaces
  cli-tui.spec.md             # CLI, slash commands, TUI/dashboard surfaces
  data-models.spec.md         # state, config, records, schemas
  validation.spec.md          # quality gates and black-box rebuild checklist
```

Adapt names to the actual repository. For apps, use `pages`, `components`,
`services`, `api`, `data-models`, and feature-specific specs. Keep each file
codebase-agnostic: conceptual references point to other rispecs, not source
paths, except in optional provenance notes.

## Required Structure for Each Rispec

Each rispec should be markdown and include enough detail for another LLM to
implement adequately without reading the original source.

```markdown
# CapabilityName
Briefly state what this capability enables users or agents to create.

## Desired Outcome Definition
- Desired Outcome: ...
- Value: ...
- Completion Signal: ...

## Current Reality
Describe the starting state, constraints, or user/system context.

## Structural Tension
Describe the dynamic relationship between Current Reality and Desired Outcome.

## Natural Progression
Explain how the capability advances through structural dynamics.

## Functional Specification
Natural language behavior, data flow, decisions, and edge conditions.

## Screens / Components / Services / Data
Use only the sections that fit this capability. Include Behavior, Layout,
Styling, API contracts, schemas, prompts, or protocols where implementation
precision matters.

## Creative Advancement Scenarios
**Creative Advancement Scenario**: Scenario Name
**User Intent**: Desired outcome they want to create
**Current Reality**: Starting state/context
**Natural Progression Steps**:
  1. Structural dynamic enables...
  2. System responds by...
  3. User advances toward...
**Achieved Outcome**: Manifested desired result
**Supporting Features**: Capabilities enabling this advancement

## Beloved Qualities to Preserve
- ...

## Implementation-Sufficient Notes
Types, APIs, command contracts, events, persistence, error behavior, and
non-obvious design decisions. Another LLM should be able to rebuild from this.

## Validation
- [ ] Creative orientation preserved
- [ ] Structural dynamics explicit
- [ ] No reactive language or forced-connection framing
- [ ] Black-box rebuild ready
```

## RISE Workflow

### Phase 1: Reverse-Engineer

1. Inventory the repository by surfaces and capabilities.
2. For each capability, ask: what does this enable users or agents to create?
3. Identify user/agent creation flows, choice points, and data movements.
4. Preserve beloved qualities: UX feel, workflow shortcuts, resilience patterns,
   extensibility seams, and successful inferences.
5. Separate implementation provenance from autonomous specification. Source paths
   may appear in an appendix, but the core spec must stand alone.

### Phase 2: Intent-Extract and Refine

For each capability, write:

- Desired Outcome: specific result created
- Current Reality: starting state and constraints
- Structural Tension: why movement wants to occur
- Natural Progression: how the system makes advancement easy
- Supporting Structures: features that make the progression inevitable

Use selective detail. Specify precise protocols, schemas, and side effects only
where common-sense inference would diverge from the desired outcome.

### Phase 3: Specify and Export

Produce `app.spec.md` as the index and collaboration guide. Export specialized
views when useful:

- technical documentation: architecture and implementation requirements
- stakeholder communication: value proposition and success metrics
- UX documentation: journey maps and interaction principles
- development team export: scenarios, APIs, schemas, tests, and quality gates

### Phase 4: Maintain and Evolve

1. Compare latest rispec modification time with git history.
2. Mine commits since the last rispec update for feature, refactor, and design
   intent breadcrumbs.
3. Map changed source files to affected rispecs.
4. Update specs with RISE language, implementation-sufficient details, and commit
   provenance for major decisions.
5. Validate every affected spec and rerun the black-box rebuild test.

Use the helper script in this skill for a first-draft automation pass:

```bash
python skills/software-development/rise-rispecs/scripts/rise_rispecs.py init --rispec-dir ./rispecs
python skills/software-development/rise-rispecs/scripts/rise_rispecs.py staleness --rispec-dir ./rispecs
python skills/software-development/rise-rispecs/scripts/rise_rispecs.py validate --rispec-dir ./rispecs
```

## Delegation Prompts

### 1. RISE/Rispec Installer

```text
Install or update the RISE/Rispec capability for this repository. Create an
in-repo Hermes skill that triggers on RISE, rispecs, creative archaeology,
living specs, and SpecLang-style specification work. Include folder conventions,
required markdown sections, anti-patterns, Phase 4 maintenance, and validation.
Add first-draft helper tooling for rispec initialization, staleness detection,
and validation. Preserve existing user changes and commit only the new files.
```

### 2. Codebase Archaeology Agent

```text
Reverse-engineer this repository into ./rispecs. Inventory the core surfaces,
services, tools, data models, workflows, and user/agent creation flows. For each
area, extract Creative Intent, Desired Outcome, Current Reality, Structural
Tension, Natural Progression, Beloved Qualities, and implementation-sufficient
behavior. Keep specs codebase-agnostic while citing source paths only as
provenance notes.
```

### 3. Rispec Generator/Exporter Agent

```text
Create ./rispecs/app.spec.md plus separated specs for components, services,
tools, pages/surfaces, data models, prompts, APIs, gateway, memory, delegation,
and scheduling as applicable. Each spec must be markdown, cross-referenced,
RISE-aligned, and sufficient for another LLM to rebuild the capability without
source access. Add technical, stakeholder, UX, and development export guidance
where useful.
```

### 4. Rispec Maintenance Agent

```text
Perform Phase 4 maintenance. Compare ./rispecs timestamps against git history,
mine commits since the last rispec update, map changed files to affected rispecs,
read diffs for intent, update specs using RISE language, cite commit hashes for
major changes, and validate that every meaningful implementation change is
reflected in living specifications.
```

### 5. RISE Validation/Review Agent

```text
Review all ./rispecs files for creative orientation, structural tension,
advancing patterns, anti-pattern language, implementation sufficiency,
cross-reference coherence, git provenance, and black-box rebuild readiness.
Output PASS or exact revision requests. Do not accept reactive framing such as
fixes, eliminates, bridges the gap, users must, or forced advancement.
```

## Quality Gates

Pre-flight gate before creating specs:

- [ ] Repository surfaces inventoried
- [ ] Existing `./rispecs/` checked for conventions
- [ ] User changes identified so they are not overwritten
- [ ] Target spec list chosen

Revision gate per spec:

- [ ] Desired Outcome Definition exists
- [ ] Current Reality exists with exact wording
- [ ] Structural Tension exists
- [ ] Natural Progression exists
- [ ] Functional behavior is implementation-sufficient
- [ ] At least one Creative Advancement Scenario where useful
- [ ] Beloved qualities identified

Escalation gate:

- Ask the user only when missing business intent, product direction, or private
  context cannot be discovered from code, commits, or supplied docs.

Abort gate:

- Stop and report if generating specs would overwrite user-authored rispecs
  without a clear merge path.

## Common Pitfalls

1. Reactive framing.
   Wrong: `This feature fixes users not being able to export.`
   Right: `This feature enables users to create portable artifacts that preserve session state.`

2. Forced-connection language.
   Wrong: `This bridges the gap between the CLI and the gateway.`
   Right: `This lets one interaction model manifest across terminal and messaging surfaces.`

3. Implementation-only documentation.
   Wrong: `Added a ResizeObserver.`
   Right: `Users create responsive visual workspaces; ResizeObserver preserves canvas fit as layout changes.`

4. Over-specifying common behavior.
   Add exact details only where divergence would matter. Let conventional plumbing
   remain inferred.

5. Missing black-box readiness.
   If another LLM cannot rebuild the behavior from the spec alone, add schemas,
   protocols, scenario steps, or examples.

6. Stale specs.
   Run git-log-driven maintenance after meaningful commits. Living specs lose
   value when implementation advances without them.

## Verification Checklist

- [ ] `./rispecs/app.spec.md` explains how to use all other specs
- [ ] Specs are separated by component/service/surface/feature
- [ ] Each spec includes Desired Outcome, Current Reality, Structural Tension,
      Natural Progression, and implementation-sufficient behavior
- [ ] Creative Advancement Scenarios replace BDD-style reactive stories
- [ ] Language avoids `fixes`, `eliminates`, `bridges the gap`, `users must`, and
      force-based phrasing
- [ ] Phase 4 maintenance cites commit hashes for major implementation changes
- [ ] Validation output is PASS or exact revision requests
- [ ] Black-box rebuild test passes: another LLM can implement adequately from
      the rispecs without original source code
