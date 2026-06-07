#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

copilot_read_input
copilot_init_session
copilot_record_event "preToolUse"

# Validate bash commands
tool_name="$(copilot_json_value '.tool_name')"
if [[ "$tool_name" == "Bash" ]]; then
    bash_command=$(copilot_json_value '.tool_input.command')
    if [ -n "$bash_command" ]; then
        if ! /a/src/scripts/git_command_validator.sh "$bash_command"; then
            exit 2
        fi
    fi
fi

exit 0
