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

# Detect positive feedback patterns
if ! printf '%s' "$prompt" | grep -Eiq '^(yes|yep|ok|okay|go ahead|continue|approved|do it|please proceed)\b'; then
    exit 0
fi

# Try to find the latest tool result from AfterTool log
latest_tool_file="$GEMINI_SESSION_DIR/_gemini_AfterTool.jsonl"
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

redirection="$(
    jq -n \
        --arg session_id "$GEMINI_SESSION_ID" \
        --arg hook_event_name "AcceptedRedirection" \
        --arg accepted_tool_use_id "$tool_use_id" \
        --arg accepted_tool_name "$tool_name" \
        --argjson accepted_tool_input "$tool_input" \
        --arg followup_instruction "$prompt" \
        --arg timestamp "$timestamp" \
        '{
            session_id: $session_id,
            hook_event_name: $hook_event_name,
            accepted_tool_use_id: $accepted_tool_use_id,
            accepted_tool_name: $accepted_tool_name,
            accepted_tool_input: $accepted_tool_input,
            followup_instruction: $followup_instruction,
            timestamp: $timestamp,
            source: "gemini_before_agent_best_effort"
        }'
)"

printf '%s\n' "$redirection" >> "$GEMINI_SESSION_DIR/_gemini_AcceptedRedirection.jsonl"
printf '%s\n' "$redirection" > "$GEMINI_SESSION_DIR/last_gemini_AcceptedRedirection.json"
# Also append to user_inputs so yes+tab content appears alongside regular prompts
printf '%s\n' "$redirection" >> "$GEMINI_SESSION_DIR/_gemini_user_inputs.jsonl"
gemini_trace "Captured best-effort Gemini accepted redirection for ${tool_name:-unknown} (${tool_use_id:-no-tool-id})"

exit 0
