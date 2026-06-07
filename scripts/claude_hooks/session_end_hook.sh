#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
transcript_path=$(echo "$input" | jq -r .transcript_path)
output_dir="/workspace/coaia-agent/.hch/sessions/$session_id"
mkdir -p "$output_dir"

# Archive complete transcript on session end
cp "$transcript_path" "$output_dir/_transcript_final.jsonl"

echo "$input" >> "$output_dir/_claude_SessionEnd.jsonl"
echo "$input" > "$output_dir/last_claude_SessionEnd.jsonl"

