#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
output_dir="/workspace/coaia-agent/.hch/sessions/$session_id"
mkdir -p "$output_dir"
echo "$input" >> "$output_dir/_claude_user_inputs.jsonl"
echo "$input" > "$output_dir/last_claude_user_inputs.jsonl" # We might monitor just the last input we gave

#echo "" >> "$output_dir/_claude_user_inputs.jsonl"
