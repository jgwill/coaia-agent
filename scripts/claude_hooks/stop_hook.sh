#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
transcript_path=$(echo "$input" | jq -r .transcript_path)
output_dir="/workspace/coaia-agent/.asterion/sessions/$session_id"
mkdir -p "$output_dir"

# Capture all assistant responses as they accumulate (JSONL parsing)
if [ -f "$transcript_path" ]; then
  jq -c 'select(.type=="assistant")' "$transcript_path" > "$output_dir/_responses_progressive.jsonl"
fi

# Save last_assistant_message as its own event stream for ceremony-session-observer
last_msg=$(echo "$input" | jq -r '.last_assistant_message // empty')
if [ -n "$last_msg" ]; then
  echo "$input" >> "$output_dir/_claude_AssistantResponse.jsonl"
  echo "$input" > "$output_dir/last_claude_AssistantResponse.json"
fi

echo "$input" >> "$output_dir/_claude_Stop.jsonl"
