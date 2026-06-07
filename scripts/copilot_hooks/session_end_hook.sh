#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

copilot_read_input
copilot_init_session
copilot_record_event "sessionEnd"

exit 0
