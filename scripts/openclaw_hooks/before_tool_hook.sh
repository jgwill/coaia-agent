#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

openclaw_read_input
openclaw_init_session
openclaw_record_event "BeforeTool"

tool_name="$(openclaw_json_value '.tool_name')"

# Standard safety check for bash commands if applicable
if [[ "$tool_name" == "Bash" ]] || [[ "$tool_name" == "bash" ]] || [[ "$tool_name" == "run_shell_command" ]]; then
    bash_command=$(openclaw_json_value '.tool_input.command')
    if [ -n "$bash_command" ]; then
        if [ -f "/a/src/scripts/git_command_validator.sh" ]; then
            if ! /a/src/scripts/git_command_validator.sh "$bash_command"; then
                exit 2
            fi
        fi
    fi
fi

exit 0
