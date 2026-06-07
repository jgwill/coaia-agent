#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session
gemini_record_event "AfterTool"
gemini_capture_transcript

# Logic for accepted plans
tool_name="$(gemini_json_value '.tool_name')"
if [ "$tool_name" = "ExitPlanMode" ] || [[ "$tool_name" == *"ExitPlanMode" ]]; then
    plan_content=$(gemini_json_value '.tool_input.plan')
    if [ -n "$plan_content" ]; then
        plans_dir="$GEMINI_SESSION_DIR/plans"
        mkdir -p "$plans_dir"
        timestamp=$(date +"%y%m%d%H%M")
        plan_file="$plans_dir/session_${GEMINI_SESSION_ID}_${timestamp}_accepted.md"
        {
            printf '%s\n' '---'
            printf 'session_id: %s\n' "$GEMINI_SESSION_ID"
            printf 'timestamp: %s\n' "$(date -Iseconds)"
            printf 'source: gemini\n'
            printf 'status: accepted\n'
            printf '%s\n\n' '---'
            printf '%s\n' "$plan_content"
        } > "$plan_file"
        gemini_trace "Saved accepted plan content to $plan_file"
    fi
fi

exit 0
