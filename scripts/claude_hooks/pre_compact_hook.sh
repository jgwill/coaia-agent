#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
output_dir="/workspace/coaia-agent/.hch/sessions/$session_id"
mkdir -p "$output_dir"
echo "$input" >> "$output_dir/_claude_PreCompact.jsonl"
#echo "" >> "$output_dir/_claude_PreCompact.jsonl"
