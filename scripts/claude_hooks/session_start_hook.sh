#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
session_dir="/workspace/coaia-agent/.hch/sessions"
mkdir -p "$session_dir/data"
session_common_data_file="$session_dir/data/session_starts_all.jsonl"
output_dir="$session_dir/$session_id"
mkdir -p "$output_dir"
echo "$input" >> "$output_dir/_claude_session_starts.jsonl"
echo "$input" > "$output_dir/last_claude_session_starts.jsonl"
echo "$input" >> "$session_common_data_file" #so we have a common file with all session starts
#echo "" >> "$output_dir/_claude_session_starts.jsonl"
