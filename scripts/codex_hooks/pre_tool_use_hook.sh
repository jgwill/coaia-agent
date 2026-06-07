#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session
codex_record_event "PreToolUse"

# Validate bash commands
tool_name="$(codex_json_value '.tool_name')"
if [[ "$tool_name" == "Bash" ]]; then
    bash_command=$(codex_json_value '.tool_input.command')
    if [ -n "$bash_command" ]; then
        if ! /a/src/scripts/git_command_validator.sh "$bash_command"; then
            exit 2
        fi
    fi
fi

codex_capture_tool_artifacts

exit 0
