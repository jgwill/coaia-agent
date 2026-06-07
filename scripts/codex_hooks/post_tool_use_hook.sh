#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session
codex_record_event "PostToolUse"
codex_capture_transcript

tool_use_id="$(codex_json_value '.tool_use_id')"
transcript_path="$(codex_json_value '.transcript_path')"
exit_code="$(
    jq -r '
        if (.tool_response | type) == "object" then
            (.tool_response.exit_code? // .tool_response.exitCode? // .tool_response.status? // empty)
        else
            empty
        end
    ' <<< "$CODEX_HOOK_INPUT" 2>/dev/null
)"

if [ -z "$exit_code" ] && [ -n "$tool_use_id" ] && [ -f "$transcript_path" ]; then
    exit_code="$(
        jq -r --arg call_id "$tool_use_id" '
            select(.type == "response_item" and .payload.type == "function_call_output" and .payload.call_id == $call_id) |
            .payload.output
        ' "$transcript_path" 2>/dev/null |
            sed -n 's/.*Process exited with code \([0-9][0-9]*\).*/\1/p' |
            tail -n 1
    )"
fi

if [ -n "$exit_code" ]; then
    status_json="$(
        jq -c --arg exit_code "$exit_code" --arg captured_at "$CODEX_CAPTURED_AT" \
            '. + {codex_tool_exit_code: $exit_code, captured_at: $captured_at, captured_by: "codex_hooks"}' \
            <<< "$CODEX_HOOK_INPUT" 2>/dev/null
    )"
    printf '%s\n' "$status_json" >> "$CODEX_SESSION_DIR/_codex_PostToolUse_status.jsonl"
fi

if [ -n "$exit_code" ] && [ "$exit_code" != "0" ] && [ "$exit_code" != "success" ]; then
    codex_record_alias "PostToolUseFailure"
fi

exit 0
