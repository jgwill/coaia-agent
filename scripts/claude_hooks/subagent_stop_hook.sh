#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)

# Determine base directory - check for /src first, then fallback to current repo location
if [ -d "/workspace/coaia-agent/.asterion/sessions" ]; then
    base_dir="/src"
else
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    base_dir="$(cd "$script_dir/../.." && pwd)"
fi

output_dir="/workspace/coaia-agent/.asterion/sessions/$session_id"
mkdir -p "$output_dir"

# Save last_assistant_message as its own event stream for ceremony-session-observer
last_msg=$(echo "$input" | jq -r '.last_assistant_message // empty')
if [ -n "$last_msg" ]; then
  echo "$input" >> "$output_dir/_claude_AssistantResponse.jsonl"
  echo "$input" > "$output_dir/last_claude_AssistantResponse.json"
fi

echo "$input" >> "$output_dir/_claude_SubagentStop.jsonl"
echo "$input" > "$output_dir/last_claude_SubagentStop.jsonl"

# --- Per-Agent Output Capture ---
agent_id=$(echo "$input" | jq -r '.agent_id // empty')
agent_type=$(echo "$input" | jq -r '.agent_type // "unknown"')
agent_transcript=$(echo "$input" | jq -r '.agent_transcript_path // empty')

if [ -n "$agent_id" ] && [ -n "$last_msg" ]; then
    agents_dir="$output_dir/agents"
    mkdir -p "$agents_dir"
    timestamp=$(date +"%y%m%d%H%M")

    # Try to load launch manifest (saved by post_tool_use_hook on Agent PostToolUse)
    launch_file="$agents_dir/$agent_id.launch.json"
    if [ -f "$launch_file" ]; then
        description=$(jq -r '.description // "unknown"' "$launch_file")
        prompt=$(jq -r '.prompt // ""' "$launch_file")
    else
        description="unknown"
        prompt=""
    fi

    # Write readable per-agent output markdown
    output_file="$agents_dir/$agent_id.output.md"
    {
        echo "---"
        echo "agent_id: $agent_id"
        echo "agent_type: $agent_type"
        echo "description: \"$description\""
        echo "completed_at: $(date -Iseconds)"
        echo "session_id: $session_id"
        [ -n "$agent_transcript" ] && echo "transcript: $agent_transcript"
        echo "---"
        echo ""
        echo "# $description"
        echo ""
        echo "## Agent Output"
        echo ""
        echo "$last_msg"
    } > "$output_file"

    # Save prompt separately if available (can be large)
    if [ -n "$prompt" ]; then
        echo "$prompt" > "$agents_dir/$agent_id.prompt.txt"
    fi

    # Symlink transcript for easy access
    if [ -n "$agent_transcript" ] && [ -f "$agent_transcript" ]; then
        ln -sf "$agent_transcript" "$agents_dir/$agent_id.transcript.jsonl" 2>/dev/null
    fi

    echo "[$timestamp] Agent '$description' ($agent_id) completed → $output_file" >> "$output_dir/trace.log"
fi
