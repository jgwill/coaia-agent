# Codex hooks mirror for `claude_hooks`

This directory mirrors the session-capture parts of `claude_hooks/mia.claude.settings.json` for Codex CLI hooks.

Codex supports these lifecycle events today:

- `SessionStart`
- `UserPromptSubmit`
- `PreToolUse`
- `PermissionRequest`
- `PostToolUse`
- `Stop`

The Claude-only events in the existing settings, such as `Notification`, `SubagentStart`, `SubagentStop`, `PreCompact`, `SessionEnd`, and `PostToolUseFailure`, do not have separate Codex hook events. `PostToolUseFailure` is approximated by `post_tool_use_hook.sh` when the Codex hook payload includes a non-zero tool status.

## Install shape

`/home/mia/.codex/hooks.json` points at the scripts in this directory by absolute path:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bash /src/scripts/codex_hooks/session_start_hook.sh"
          }
        ]
      }
    ]
  }
}
```

`/home/mia/.codex/config.toml` must also contain:

```toml
[features]
codex_hooks = true
```

## Output

Each hook writes compact JSONL under:

```text
/src/_sessiondata/<session_id>/
```

Main streams:

- `_codex_session_starts.jsonl`
- `_codex_user_inputs.jsonl`
- `_codex_PreToolUse.jsonl`
- `_codex_PermissionRequest.jsonl`
- `_codex_PostToolUse.jsonl`
- `_codex_Stop.jsonl`
- `_codex_hooks_all.jsonl`
- `_codex_transcript_latest.jsonl`
- `_codex_responses_progressive.jsonl`

For compatibility with the Claude observer pattern, `stop_hook.sh` also writes `_responses_progressive.jsonl` when a Codex transcript path is available.

## Notes from the Codex hook docs

Codex loads hooks from `hooks.json` or inline `[hooks]` tables next to active config layers. Multiple matching hooks run concurrently, so the prompt-side feedback hooks write independent files and avoid stdout. Hook commands receive one JSON object on stdin, and `Stop` hooks must not emit plain text on stdout.
