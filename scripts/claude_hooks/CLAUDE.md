future refinement related issue is : * jgwill/src#319

# Hook Architecture

All agent hook suites delegate git command validation to a single shared script:
`/a/src/scripts/git_command_validator.sh`

This script is the **single source of truth** for forbidden git patterns (aggressive add/commit).
Agents covered: claude_hooks, codex_hooks, gemini_hooks, copilot_hooks.

## Forbidden Patterns

- `git add -A` / `git add .` / `git add --all`
- `git commit -a` / `git commit -am` / `git commit --all`

The validator strips quoted `-m "..."` / `--message "..."` content before checking for `-a`
to avoid false positives on commit message text that contains `-a` as a substring.

## Hook Suite Locations

| Agent   | Hook dir                            | Key hook file          |
|---------|-------------------------------------|------------------------|
| Claude  | `scripts/claude_hooks/`             | `pre_tool_use_hook.sh` |
| Codex   | `scripts/codex_hooks/`              | `pre_tool_use_hook.sh` |
| Gemini  | `scripts/gemini_hooks/`             | `before_tool_hook.sh`  |
| Copilot | `scripts/copilot_hooks/`            | `pre_tool_use_hook.sh` |

All hooks also save session artifacts to `/workspace/coaia-agent/.hch/sessions/<session_id>/`.

## Related Docs

`/src/agent-session-insights/CLAUDE.md`

* Another variation may be at `/workspace/AetherialProject/src/agent-session-insights/`
  or `/src/AetherialProject/src/agent-session-insights/` depending on the system.

`/workspace/coaia-agent/.hch/sessions/CLAUDE.md`

# Discovery timestamp 2510211520:
## https://github.com/disler/claude-code-hooks-mastery

* Forked and cloned locally under `/src/palimpsest/claude-code-hooks-mastery-mia`
* https://github.com/miadisabelle/skills-mia may help create skills from these hooks.
  Cloned fork at `/src/palimpsest/skills-mia`
