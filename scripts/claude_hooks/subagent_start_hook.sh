#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)

# Determine base directory - check for /src first, then fallback to current repo location
if [ -d "/workspace/coaia-agent/.hch/sessions" ]; then
    base_dir="/src"
else
    # Get script directory and go up two levels to repo root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    base_dir="$(cd "$script_dir/../.." && pwd)"
fi

output_dir="$base_dir/_sessiondata/$session_id"
mkdir -p "$output_dir"
echo "$input" >> "$output_dir/_claude_SubagentStart.jsonl"
echo "$input" >  "$output_dir/last_claude_SubagentStart.json"
