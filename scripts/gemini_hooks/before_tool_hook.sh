#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session
gemini_record_event "BeforeTool"

# Capture tool artifacts
tool_name="$(gemini_json_value '.tool_name')"
timestamp=$(date +"%y%m%d%H%M%S")

# Validate bash commands
if [[ "$tool_name" == "Bash" ]] || [[ "$tool_name" == "bash" ]]; then
    bash_command=$(gemini_json_value '.tool_input.command')
    if [ -n "$bash_command" ]; then
        if ! /a/src/scripts/git_command_validator.sh "$bash_command"; then
            exit 2
        fi
    fi
fi

case "$tool_name" in
    *write_file|*Write|*replace|*Edit)
        proposed_dir="$GEMINI_SESSION_DIR/proposed"
        mkdir -p "$proposed_dir"
        file_path=$(gemini_json_value '.tool_input.file_path // .tool_input.path // empty')
        content=$(gemini_json_value '.tool_input.content // .tool_input.new_string // empty')
        
        if [ -n "$content" ]; then
            filename=$(basename "${file_path:-proposal}")
            safe_name=$(printf '%s_%s' "$timestamp" "$filename" | tr -c 'A-Za-z0-9._-' '_')
            printf '%s' "$content" > "$proposed_dir/$safe_name"
            gemini_trace "Saved proposed artifact for $tool_name to proposed/$safe_name"
        fi
        ;;
    *ExitPlanMode)
        plan_content=$(gemini_json_value '.tool_input.plan')
        if [ -n "$plan_content" ]; then
            plans_dir="$GEMINI_SESSION_DIR/plans"
            mkdir -p "$plans_dir"
            plan_file="$plans_dir/session_${GEMINI_SESSION_ID}_${timestamp}.md"
            {
                printf '%s\n' '---'
                printf 'session_id: %s\n' "$GEMINI_SESSION_ID"
                printf 'timestamp: %s\n' "$(date -Iseconds)"
                printf 'source: gemini\n'
                printf '%s\n\n' '---'
                printf '%s\n' "$plan_content"
            } > "$plan_file"
            gemini_trace "Saved plan content to $plan_file"
        fi
        ;;
esac

exit 0
