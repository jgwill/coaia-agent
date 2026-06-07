#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

openclaw_read_input
openclaw_init_session
openclaw_record_event "SessionEnd"

exit 0
