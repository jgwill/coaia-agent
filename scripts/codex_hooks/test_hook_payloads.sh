#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${CODEX_SESSIONDATA_ROOT:-/tmp/codex_hooks_test_sessiondata}"
SESSION_ID="codex-hooks-smoke-$(date +%s)"
TRANSCRIPT="$ROOT/$SESSION_ID/transcript.jsonl"

rm -rf "$ROOT/$SESSION_ID"
mkdir -p "$ROOT/$SESSION_ID"

printf '%s\n' \
    '{"type":"event_msg","payload":{"type":"agent_message","message":"test assistant message"}}' \
    > "$TRANSCRIPT"

payload_base="$(
    jq -n \
        --arg session_id "$SESSION_ID" \
        --arg transcript_path "$TRANSCRIPT" \
        --arg cwd "$PWD" \
        --arg model "gpt-5.4-mini" \
        '{session_id: $session_id, transcript_path: $transcript_path, cwd: $cwd, model: $model}'
)"

printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"SessionStart", source:"startup"}' |
    CODEX_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/session_start_hook.sh"

printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"UserPromptSubmit", turn_id:"turn-test", prompt:"ok continue with the test"}' |
    CODEX_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/user_prompt_submit_hook.sh"

printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"PreToolUse", turn_id:"turn-test", tool_name:"Bash", tool_use_id:"tool-test", tool_input:{command:"printf smoke"}}' |
    CODEX_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/pre_tool_use_hook.sh"

printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"PostToolUse", turn_id:"turn-test", tool_name:"Bash", tool_use_id:"tool-test", tool_input:{command:"printf smoke"}, tool_response:{exit_code:0, output:"smoke"}}' |
    CODEX_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/post_tool_use_hook.sh"

printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"Stop", turn_id:"turn-test", stop_hook_active:false, last_assistant_message:"smoke complete"}' |
    CODEX_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/stop_hook.sh"

test -s "$ROOT/$SESSION_ID/_codex_session_starts.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_user_inputs.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_PreToolUse.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_PostToolUse.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_Stop.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_AssistantResponse.jsonl"
test -s "$ROOT/$SESSION_ID/_codex_responses_progressive.jsonl"

printf '%s\n' "$ROOT/$SESSION_ID"
