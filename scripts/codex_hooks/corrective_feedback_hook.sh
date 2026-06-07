#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session

prompt="$(codex_json_value '.prompt')"
if [ -z "$prompt" ]; then
    exit 0
fi

if ! printf '%s' "$prompt" | grep -Eiq '^(no|do not|don'\''t|stop|instead|wrong|reject|not that|hold on)\b'; then
    exit 0
fi

latest_tool="$(codex_latest_tool_json "$CODEX_SESSION_DIR/_codex_PreToolUse.jsonl")"
tool_use_id="$(printf '%s' "$latest_tool" | jq -r '.tool_use_id // empty' 2>/dev/null)"
tool_name="$(printf '%s' "$latest_tool" | jq -r '.tool_name // "unknown"' 2>/dev/null)"
tool_input="$(printf '%s' "$latest_tool" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')"
timestamp="$(date -Iseconds)"

feedback="$(
    jq -n \
        --arg session_id "$CODEX_SESSION_ID" \
        --arg hook_event_name "CorrectiveFeedback" \
        --arg rejected_tool_use_id "$tool_use_id" \
        --arg rejected_tool_name "$tool_name" \
        --argjson rejected_tool_input "$tool_input" \
        --arg user_feedback_message "$prompt" \
        --arg timestamp "$timestamp" \
        '{
            session_id: $session_id,
            hook_event_name: $hook_event_name,
            rejected_tool_use_id: $rejected_tool_use_id,
            rejected_tool_name: $rejected_tool_name,
            rejected_tool_input: $rejected_tool_input,
            user_feedback_message: $user_feedback_message,
            timestamp: $timestamp,
            source: "codex_user_prompt_submit_best_effort"
        }'
)"

printf '%s\n' "$feedback" >> "$CODEX_SESSION_DIR/_codex_CorrectiveFeedback.jsonl"
printf '%s\n' "$feedback" > "$CODEX_SESSION_DIR/last_codex_CorrectiveFeedback.json"
codex_trace "Captured best-effort Codex corrective feedback for ${tool_name:-unknown} (${tool_use_id:-no-tool-id})"

exit 0
