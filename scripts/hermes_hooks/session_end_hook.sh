#!/bin/bash
# Hermes Session End Hook
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

hermes_read_input
hermes_init_session
hermes_record_event "session_end"
