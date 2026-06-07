#!/bin/bash
# Corrective Feedback Hook
# Captures when user rejects tools and provides corrective guidance
# Runs on UserPromptSubmit and parses transcript for tool rejections

input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)
user_prompt=$(echo "$input" | jq -r .prompt)

# Determine base directory
if [ -d "/workspace/coaia-agent/.asterion/sessions" ]; then
    base_dir="/src"
else
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    base_dir="$(cd "$script_dir/../.." && pwd)"
fi

output_dir="/workspace/coaia-agent/.asterion/sessions/$session_id"
mkdir -p "$output_dir"

# Parse transcript for tool rejections (tool_result with is_error:true)
transcript_file=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -f "$transcript_file" ]; then
    # Get recent tool rejections from transcript (last 50 entries)
    # Process each transcript entry
    tail -50 "$transcript_file" 2>/dev/null | while IFS= read -r line; do
        # Check if this line contains a tool rejection
        is_rejection=$(echo "$line" | jq -r 'select(.message.content[]? | .type == "tool_result" and .is_error == true) | "yes"' 2>/dev/null)

        if [ "$is_rejection" = "yes" ]; then
            # Extract rejection details
            tool_use_id=$(echo "$line" | jq -r '.message.content[] | select(.type == "tool_result") | .tool_use_id' 2>/dev/null)
            rejection_content=$(echo "$line" | jq -r '.message.content[] | select(.type == "tool_result") | .content' 2>/dev/null)
            rejection_timestamp=$(echo "$line" | jq -r '.timestamp' 2>/dev/null)

            # Extract user feedback from rejection content
            # Format: "The user doesn't want to proceed... To tell you how to proceed, the user said:\n<feedback>"
            # The feedback is everything after the first line
            user_feedback=$(echo "$rejection_content" | tail -n +2)

            if [ -n "$tool_use_id" ] && [ -n "$user_feedback" ]; then
                # Check if we already captured this rejection
                already_captured=false
                if [ -f "$output_dir/_claude_CorrectiveFeedback.jsonl" ]; then
                    if grep -q "\"rejected_tool_use_id\":\"$tool_use_id\"" "$output_dir/_claude_CorrectiveFeedback.jsonl" 2>/dev/null; then
                        already_captured=true
                    fi
                fi

                if [ "$already_captured" = false ]; then
                    # Get the original tool proposal from PreToolUse
                    pretool_file="$output_dir/_claude_PreToolUse.jsonl"
                    tool_name="unknown"
                    tool_input="{}"

                    if [ -f "$pretool_file" ]; then
                        tool_proposal=$(grep "\"tool_use_id\":\"$tool_use_id\"" "$pretool_file" | tail -1)
                        if [ -n "$tool_proposal" ]; then
                            tool_name=$(echo "$tool_proposal" | jq -r '.tool_name // "unknown"')
                            tool_input=$(echo "$tool_proposal" | jq -r '.tool_input // {}')
                        fi
                    fi

                    # Create corrective feedback entry
                    timestamp=$(date -Iseconds)

                    # Build corrective feedback JSON
                    corrective_feedback=$(jq -n \
                        --arg session_id "$session_id" \
                        --arg hook_event_name "CorrectiveFeedback" \
                        --arg rejected_tool_use_id "$tool_use_id" \
                        --arg rejected_tool_name "$tool_name" \
                        --argjson rejected_tool_input "$tool_input" \
                        --arg user_feedback_message "$user_feedback" \
                        --arg rejection_timestamp "$rejection_timestamp" \
                        --arg timestamp "$timestamp" \
                        '{
                            session_id: $session_id,
                            hook_event_name: $hook_event_name,
                            rejected_tool_use_id: $rejected_tool_use_id,
                            rejected_tool_name: $rejected_tool_name,
                            rejected_tool_input: $rejected_tool_input,
                            user_feedback_message: $user_feedback_message,
                            rejection_timestamp: $rejection_timestamp,
                            timestamp: $timestamp
                        }')

                    # Append to corrective feedback log
                    echo "$corrective_feedback" >> "$output_dir/_claude_CorrectiveFeedback.jsonl"
                    echo "$corrective_feedback" > "$output_dir/last_claude_CorrectiveFeedback.json"

                    # Log for trace
                    echo "Captured corrective feedback for rejected tool: $tool_name ($tool_use_id) at $(date '+%Y-%m-%d %H:%M:%S')" >> "$output_dir/trace.log"
                fi
            fi
        fi
    done
fi

exit 0
