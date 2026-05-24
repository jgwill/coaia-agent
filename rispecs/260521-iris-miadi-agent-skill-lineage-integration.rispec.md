# Iris → Miadi-Agent Skill Lineage Integration — RISE Specification

**Version**: 0.1.0  
**Document ID**: iris-miadi-agent-skill-lineage-integration-260521  
**Last Updated**: 2026-05-21  
**Status**: Draft, spec-only; no runtime code changed  
**Authoring context**: Iris/Hermes skillset commitment wave `miadi-iris-skillset-commiting-260521`  
**Source branch**: `guillaumedescoteauxisabelle/orko.private` branch `kaia` at `116a0f9`

## 1. Reverse Engineering

Iris/Hermes has just converted several field-learned practices into issue-linked skills and references. The relevant source wave is:

| Source | Commit | Meaning for Coaia-Agent |
|---|---:|---|
| guillaumedescoteauxisabelle/orko.private#70 | `ecef08a` | Codex/tmux prompt submission must verify actual acceptance, not visible paste state. |
| guillaumedescoteauxisabelle/orko.private#69 and #91 | `3a5ebbf` | Cross-agent handoff now includes Storyweaver/Chronicle tmux steering with pane capture, cwd grounding, prompt-file replay, and acceptance verification. |
| guillaumedescoteauxisabelle/orko.private#83 | `5cfd58a` | PR/rebase/telemetry workflows should preserve meaningful agent-created state and avoid blocked force-push retries. |
| guillaumedescoteauxisabelle/orko.private#92 | `fc9c398` | Foundations packets can be imported as Chronicle-ready research/engineering/narrative source material. |
| guillaumedescoteauxisabelle/orko.private#93 | `b4bba2f` | Daily reflections can become Chronicle seed packets when a day has meaningful work and no episode exists yet. |
| guillaumedescoteauxisabelle/orko.private#94 | `2748810` | Gemini extension authoring must respect Gemini-native extension structure instead of copying Codex/Copilot plugin assumptions. |
| guillaumedescoteauxisabelle/orko.private#65 | `116a0f9` | The wave is captured in the Iris evolution timeline and a Claude-backed miaco PDE decomposition. |

Codex then produced Miadi-Agent issue recommendations, which Iris/Hermes created in `jgwill/Miadi`:

| Miadi issue | Recommendation |
|---|---|
| jgwill/Miadi#345 | Teach Miadi-Agent acceptance-aware live tmux steering. |
| jgwill/Miadi#346 | Add an issue-linked Iris-to-Miadi skill lineage ledger. |
| jgwill/Miadi#347 | Codify PR rebase fallback and telemetry preservation for Miadi-Agent work. |
| jgwill/Miadi#348 | Promote foundations and Chronicle seed imports into Miadi-Agent runtime memory. |
| jgwill/Miadi#349 | Create a provider-native extension surface matrix for Miadi-Agent. |

Existing Miadi anchors named by Mighty Eagle / IronSilk contracts:

- jgwill/Miadi#250 — Hermes Agent runtime boundary.
- jgwill/Miadi#252 — Miadi-Agent rispec thread.
- jgwill/Miadi#254 — A2A runtime contract, fork policy, promotion path.
- jgwill/Miadi#258 — git sync safety around untracked files.
- jgwill/Miadi#265 — Hermes Navigator v1 focus contract.
- jgwill/Miadi#239 — milestone-aware chart routing and PDE chain orchestration.
- jgwill/Miadi#261 — cross-instance collaboration / MiaClaw direction.
- jgwill/Miadi#262 — self-referential loops and deep-search survey.

## 2. Intent

Coaia-Agent should treat this Iris wave as integration evidence, not as a direct implementation order.

Desired outcome:

1. Coaia-Agent can consume Iris/Hermes skill lineage as runtime-memory and planning material.
2. Miadi-Agent / Mighty Eagle recommendations remain traceable through GitHub issues, commits, and source skill paths.
3. Coaia-Agent preserves the same discipline in its own runtime: verified handoffs, provenance, telemetry preservation, foundations import, and provider-native extension boundaries.
4. The integration can be understood by agents who did not attend the session.

Current reality:

- Coaia-Agent already has rispecs for prompt skill runtime, PDE/STC lifecycle, skill/plugin authoring, runtime-memory consumption, ACP/gateway surfaces, and visualizer planning flow.
- The new Iris wave is not yet represented as a Coaia planning surface.
- jgwill/Miadi now has five recommendation issues, but Coaia-Agent needs a local strategic map so its own runtime planning can consume those issues without guessing.

Structural tension:

Coaia-Agent wants to become a runtime steward, but Iris is evolving faster as a field-learning agent. The bridge is not to copy Iris blindly; it is to make Iris's verified practices visible as runtime contracts, memory schemas, and issue-backed planning lanes.

## 3. Specification

### 3.1 Integration lanes

Coaia-Agent should track this wave through five lanes:

1. **Live session steering lane**
   - Source: orko.private#70, #69, #91.
   - Miadi issue: jgwill/Miadi#345.
   - Coaia implication: any future Coaia tmux/session-control tool must distinguish pasted text from accepted prompts and record capture/submit/verify state.

2. **Skill lineage ledger lane**
   - Source: orko.private#65, #92, #93, #94.
   - Miadi issue: jgwill/Miadi#346.
   - Coaia implication: Coaia runtime memory should be able to record source issue, source commit, source path, local interpretation, status, and downstream anchor issue.

3. **Git/telemetry preservation lane**
   - Source: orko.private#83.
   - Miadi issue: jgwill/Miadi#347.
   - Coaia implication: tracked telemetry such as `.coaia` JSONL, PDE folders, runtime traces, and chart artifacts should be classified and secret-scanned before being preserved, not treated as disposable dirt.

4. **Foundations and Chronicle import lane**
   - Source: orko.private#92 and #93.
   - Miadi issue: jgwill/Miadi#348.
   - Coaia implication: foundations packets and reflection packets should enter memory with provenance, academic cautions, engineering implications, narrative use, and import-ready status separated from generated media.

5. **Provider-native extension lane**
   - Source: orko.private#94, #70, #69, #91.
   - Miadi issue: jgwill/Miadi#349.
   - Coaia implication: Coaia should keep provider-neutral capability intent separate from provider-native execution surfaces: Gemini extensions, Codex skills/plugins, Copilot plugin/instructions, Hermes skills/runtime hooks.

### 3.2 Minimal lineage record shape

A future Coaia/Miadi ledger entry should be able to express:

```yaml
id: iris-wave-260521-<slug>
source:
  repo: guillaumedescoteauxisabelle/orko.private
  branch: kaia
  commit: <hash>
  issue: <owner/repo#number>
  path: <source skill/reference path>
miadi:
  recommendation_issue: jgwill/Miadi#<number>
  anchor_issues: [jgwill/Miadi#250]
coaia:
  rispec: rispecs/260521-iris-miadi-agent-skill-lineage-integration.rispec.md
  lane: live-session-steering | lineage-ledger | git-telemetry | foundations-import | provider-native-extension
  status: candidate | accepted-for-spec | implemented | verified | superseded
provenance:
  created_by: Iris/Hermes
  codex_recommendation_file: /tmp/miadi-agent-recommendations-from-iris.json
  notes: <why this matters>
```

### 3.3 Local Iris source corpus

Coaia-Agent should treat the copied Iris corpus as local source material for self-evolution before creating new runtime behavior.

Primary local sources:

- `/workspace/coaia-agent/iris/skills/`
- `/workspace/coaia-agent/iris/memories/`
- `/workspace/coaia-agent/iris/voice-episodes/`
- `/workspace/coaia-agent/iris/skills/media/voice-episode-archiving/SKILL.md`

Reusable patterns to extract into Coaia rispecs:

- Miadi Chronicle preproduction as a seed-packet workflow before media generation.
- Voice episodes as durable folders containing script, narration, audio, revision notes, indexes, and optional machine-readable metadata.
- Infrastructure research becoming Chronicle material through three audiences: academic readers, engineering readers, and narrative readers.
- Cross-agent lineage fields such as source repo, issue, branch, external agent session id, episode type, publishing status, and downstream chart/rispec link.
- Daily reflection or session harvest producing one self-evolution item: behavior correction, skill patch, memory candidate, named pattern, cron prompt, or rispec update.

### 3.4 Supervised tmux co-working loop

When Coaia-Agent drives Iris/Hermes sessions in tmux, it should behave as a supervisor of living action rooms rather than as a one-shot command sender.

Functional contract:

1. Capture pane state and record terminal metadata: host, tmux session, group/window/pane where available, cwd, branch session id, original session id, repo focus, waiting prompt, and intended output.
2. Submit Enter only when a prompt is waiting for acceptance.
3. While the remote agent works, sleep/wait rather than interrupting.
4. Peek periodically with `tmux capture-pane` and classify state as waiting, analyzing, using tools, blocked, complete, or needing steering.
5. Send additional instructions to active Hermes sessions as `/steer <message>` so the run is guided without cancellation.
6. Harvest outputs only after verifying concrete handles: paths, issue URLs, commits, branch names, chart ids, episode folders, or saved artifacts.
7. Update the relevant structural-tension action step and, when the work changes the story of the system, create narrative beats.

### 3.5 Relation to existing Coaia rispecs

- `prompt-skill-runtime.spec.md`: should consume the lineage ledger as skill/runtime provenance.
- `skill-and-plugin-authoring.spec.md`: should inherit provider-native extension distinctions before authoring new Coaia skill/plugin surfaces.
- `pde-stc-session-lifecycle.spec.md`: should treat the miaco PDE from orko.private#65 as a precedent for decomposition artifacts feeding runtime planning.
- `github-project-runtime-memory-consumption.spec.md`: should become the projection target for GitHub issue metadata once Miadi/Coaia issue links are formalized.
- `visualizer-planning-narrative-flow.spec.md`: can later visualize the five integration lanes as narrative/runtime relations.
- Future terminal/session rispec work should represent tmux sessions as structural-tension action rooms with current state, steering history, and verified harvest outputs.

## 4. Export / Strategic Plan

Recommended sequencing:

1. **Record, do not implement yet**
   - Keep this rispec as a strategic bridge.
   - Do not edit Coaia runtime code from this wave alone.

2. **Promote the ledger lane first**
   - A lineage ledger lets Coaia consume future Iris/Miadi issues without re-reading every skill diff.
   - jgwill/Miadi#346 is the best first anchor.

3. **Bind live steering to approval and provenance**
   - jgwill/Miadi#345 should be interpreted with Coaia's governance and JSONL preservation rules.
   - Acceptance-aware steering is useful only if its attempts become auditable artifacts.

4. **Use git/telemetry discipline as a safety gate**
   - Before any Coaia automation creates or mutates `.coaia`/PDE artifacts, apply jgwill/Miadi#347's preservation rules.

5. **Treat foundations imports as runtime memory, not media generation**
   - jgwill/Miadi#348 should inform memory schemas before it triggers audio/visual creation.

6. **Keep provider surfaces native**
   - jgwill/Miadi#349 should prevent a common anti-pattern: copying a plugin format from one provider into another provider's ecosystem.

## 5. Acceptance Criteria

- [ ] This rispec is present in `/a/src/coaia-agent/rispecs/`.
- [ ] It names all seven related orko.private issues: #65, #69, #70, #83, #91, #92, #93, #94.
- [ ] It names all five Miadi recommendation issues: #345, #346, #347, #348, #349.
- [ ] It distinguishes proven Iris behavior from proposed Miadi/Coaia implementation.
- [ ] It defines a minimal lineage record shape that can later become JSONL or GitHub metadata.
- [ ] It keeps `/src/Miadi` untouched and treats `jgwill/Miadi` issues as planning anchors.
- [ ] It names `/workspace/coaia-agent/iris/` as the local Iris source corpus for skills, memories, and voice episodes.
- [ ] It specifies the supervised tmux loop: capture, submit, sleep, peek, `/steer`, verify, harvest, chart/beat update.

## 6. Open Questions

1. Should the lineage ledger live first as Markdown/YAML in rispecs, as `.coaia` JSONL, or as GitHub project metadata?
2. Which runtime owns live tmux steering: Coaia-Agent directly, Hermes Navigator as child capability, or Miadi-Agent as parent policy layer?
3. Should foundations imports from Iris become Coaia runtime memory before or after Mighty Eagle defines its parent/child foundations boundary?
4. How should provider-native extension matrices be projected into Coaia's own skill/plugin authoring spec without overfitting to today's CLI versions?
