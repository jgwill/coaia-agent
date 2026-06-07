#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${GEMINI_SESSIONDATA_ROOT:-/tmp/gemini_hooks_test_sessiondata}"
SESSION_ID="gemini-hooks-smoke-$(date +%s)"
TRANSCRIPT="$ROOT/$SESSION_ID/transcript.jsonl"

rm -rf "$ROOT/$SESSION_ID"
mkdir -p "$ROOT/$SESSION_ID"

printf '%s\n' \
    '{"type":"assistant_message","message":"test assistant message"}' \
    > "$TRANSCRIPT"

payload_base="$(
    jq -n \
        --arg session_id "$SESSION_ID" \
        --arg transcript_path "$TRANSCRIPT" \
        --arg cwd "$PWD" \
        --arg model "gemini-2.0-flash" \
        '{session_id: $session_id, transcript_path: $transcript_path, cwd: $cwd, model: $model}'
)"

printf "Running smoke tests for Gemini hooks...\n"

# SessionStart
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"SessionStart", source:"startup"}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/session_start_hook.sh"

# BeforeAgent (Prompt Submit)
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"BeforeAgent", prompt:"ok continue with the test"}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/before_agent_hook.sh"

# BeforeTool
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"BeforeTool", tool_name:"Bash", tool_use_id:"tool-test", tool_input:{command:"printf smoke"}}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/before_tool_hook.sh"

# AfterTool
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"AfterTool", tool_name:"Bash", tool_use_id:"tool-test", tool_input:{command:"printf smoke"}, tool_response:{exit_code:0, output:"smoke"}}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/after_tool_hook.sh"

# AfterAgent
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"AfterAgent", stop_hook_active:false, last_assistant_message:"smoke complete"}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/after_agent_hook.sh"

# SessionEnd
printf '%s' "$payload_base" |
    jq '. + {hook_event_name:"SessionEnd", reason:"exit"}' |
    GEMINI_SESSIONDATA_ROOT="$ROOT" bash "$SCRIPT_DIR/session_end_hook.sh"

# Verification
printf "Verifying captured files...\n"
test -s "$ROOT/$SESSION_ID/_gemini_SessionStart.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_BeforeAgent.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_BeforeTool.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_AfterTool.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_AfterAgent.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_SessionEnd.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_AssistantResponse.jsonl"
test -s "$ROOT/$SESSION_ID/_gemini_hooks_all.jsonl"

printf "Smoke tests PASSED!\n"
printf "Output directory: %s\n" "$ROOT/$SESSION_ID"
ls -R "$ROOT/$SESSION_ID"
