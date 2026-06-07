# Corrective Feedback Hook

Captures user feedback when tools are rejected, enabling MMOT (Managerial Moment of Truth) workflow for continuous learning.

## What It Does

When you reject a tool proposal (click "No" on permission dialog) and provide corrective feedback, this hook:

1. Parses the session transcript for tool rejection events
2. Extracts your corrective feedback message
3. Links feedback to the rejected tool proposal
4. Stores structured data for later processing

## Captured Data

Each rejection is stored in `_sessiondata/<session_id>/_claude_CorrectiveFeedback.jsonl`:

```json
{
  "session_id": "...",
  "hook_event_name": "CorrectiveFeedback",
  "rejected_tool_use_id": "toolu_...",
  "rejected_tool_name": "mcp__charts...add_action_step",
  "rejected_tool_input": {
    "parentChartId": "chart_...",
    "actionStepTitle": "...",
    "currentReality": "..."
  },
  "user_feedback_message": "Your corrective instructions here...",
  "rejection_timestamp": "2026-01-30T12:51:13.024Z",
  "timestamp": "2026-01-30T08:14:57-05:00"
}
```

## Installation

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /src/scripts/claude_hooks/user_prompt_submit_hook.sh"
          },
          {
            "type": "command",
            "command": "bash /src/scripts/claude_hooks/corrective_feedback_hook.sh"
          }
        ]
      }
    ]
  }
}
```

## How It Works

### Hook Event Flow

1. **Tool Proposed** → `PreToolUse` event captured
2. **Permission Dialog Shown** → User sees proposal
3. **User Clicks "No"** → Provides corrective feedback
4. **Rejection Recorded** → Transcript contains `tool_result` with `is_error: true`
5. **Next User Message** → `UserPromptSubmit` hook fires
6. **Hook Parses Transcript** → Finds recent rejections
7. **Corrective Feedback Stored** → Links rejection to feedback

### Deduplication

The hook checks if a rejection has already been captured to avoid duplicates. Each `tool_use_id` is only captured once.

### Transcript Parsing

The hook reads the session transcript file (`.jsonl`) and looks for:

```json
{
  "type": "tool_result",
  "content": "The user doesn't want to proceed... the user said:\n<your feedback>",
  "is_error": true,
  "tool_use_id": "toolu_..."
}
```

## Future Integration: MMOT Workflow

This captured data feeds into the Managerial Moment of Truth workflow:

1. **Corrective feedback captured** (this hook)
2. **Supporting LLM reviews** rejected plans + your feedback
3. **Analysis stored** in KINSHIP.md
4. **Learning loop** improves future planning

See `/src/llms/llms-managerial-moment-of-truth.md` for MMOT framework details.

## Troubleshooting

### No feedback captured

**Check:**
- Hook is configured in `~/.claude/settings.json`
- Rejection was through permission dialog (not just stopping/canceling)
- Transcript file exists and is readable

**Debug:**
```bash
# Check if hook is running
tail -10 /src/_sessiondata/<session_id>/trace.log

# Check for rejection entries
grep "is_error.*true" ~/.claude/projects/<project>/<session_id>.jsonl

# Manually test hook
cd /src/_sessiondata/<session_id>
bash /src/scripts/claude_hooks/corrective_feedback_hook.sh <<EOF
{"session_id":"<session_id>","transcript_path":"<transcript_path>","hook_event_name":"UserPromptSubmit","prompt":"test","permission_mode":"default"}
EOF
```

### Duplicate entries

The hook includes deduplication logic. If you see duplicates, check that the hook isn't being run multiple times from different configurations.

## Related Files

- `/src/scripts/claude_hooks/corrective_feedback_hook.sh` - Hook implementation
- `/src/scripts/claude_hooks/sample-home-dotclaude-settings.json` - Sample configuration
- `/src/llms/llms-managerial-moment-of-truth.md` - MMOT framework
- `/src/llms/llms-creative-orientation.txt` - Creative process framework
- `jgwill/src#354` - GitHub issue tracking this feature
