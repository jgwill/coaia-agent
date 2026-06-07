#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session

prompt="$(gemini_json_value '.prompt')"
if [ -z "$prompt" ]; then
    exit 0
fi

# Detect negative feedback patterns
if ! printf '%s' "$prompt" | grep -Eiq '^(no|do not|don'\''t|stop|instead|wrong|reject|not that|hold on)\b'; then
    exit 0
fi

# Try to find the latest tool proposal from BeforeTool log
latest_tool_file="$GEMINI_SESSION_DIR/_gemini_BeforeTool.jsonl"
if [ -f "$latest_tool_file" ]; then
    latest_tool=$(tail -n 1 "$latest_tool_file")
    tool_use_id=$(printf '%s' "$latest_tool" | jq -r '.tool_use_id // empty')
    tool_name=$(printf '%s' "$latest_tool" | jq -r '.tool_name // "unknown"')
    tool_input=$(printf '%s' "$latest_tool" | jq -c '.tool_input // {}')
else
    tool_use_id=""
    tool_name="unknown"
    tool_input="{}"
fi

timestamp="$(date -Iseconds)"

feedback="$(
    jq -n \
        --arg session_id "$GEMINI_SESSION_ID" \
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
            source: "gemini_before_agent_best_effort"
        }'
)"

printf '%s\n' "$feedback" >> "$GEMINI_SESSION_DIR/_gemini_CorrectiveFeedback.jsonl"
printf '%s\n' "$feedback" > "$GEMINI_SESSION_DIR/last_gemini_CorrectiveFeedback.json"
gemini_trace "Captured best-effort Gemini corrective feedback for ${tool_name:-unknown} (${tool_use_id:-no-tool-id})"

exit 0
