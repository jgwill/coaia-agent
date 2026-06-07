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
echo "$input" >> "$output_dir/_claude_PreToolUse.jsonl"

# --- Tool-Specific Logic ---
tool_name=$(echo "$input" | jq -r .tool_name)

if [ "$tool_name" = "Bash" ]; then
    bash_command=$(echo "$input" | jq -r '.tool_input.command // empty')
    if [ -n "$bash_command" ]; then
        # Call the centralized git command validator
        if ! /a/src/scripts/git_command_validator.sh "$bash_command"; then
            exit 2
        fi
    fi
fi

if [ "$tool_name" = "ExitPlanMode" ]; then
    # Create plans directory
    plans_dir="$output_dir/plans"
    mkdir -p "$plans_dir"
    
    # Generate timestamp in yyMMddHHmm format
    timestamp=$(date +"%y%m%d%H%M")
    
    # Extract plan content
    plan_content=$(echo "$input" | jq -r '.tool_input.plan // empty')
    
    # Only save if plan content exists
    if [ -n "$plan_content" ]; then
        plan_file="$plans_dir/session_${session_id}_${timestamp}.md"
        echo "$plan_content" > "$plan_file"
	 #Add the content of the Plan as observation to the trace
	 #/src/miette/claude-plan-insights/miette_claude_plan_perspective_claude.sh
	 #./miette_claude_plan_perspective.sh

        ((cd /src/miette/claude-plan-insights && \
                ./miette_claude_plan_perspective_claude.sh $plan_file) \
			&& echo "Plan content parsed thru Miette at $(tlid min)" >> "$output_dir/trace.log" || echo "Miette parsing failed at $(tlid min)" >> "$output_dir/trace.log" ) &

    fi
elif [ "$tool_name" = "Write" ]; then
    # Create the 'proposed' directory for storing agent's proposed files
    proposed_dir="$output_dir/proposed"
    mkdir -p "$proposed_dir"

    # Extract file path and content from the tool input
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    file_content=$(echo "$input" | jq -r '.tool_input.content // empty')
    
    # Proceed only if both file_path and file_content are non-empty
    if [ -n "$file_path" ] && [ -n "$file_content" ]; then
        # Extract just the filename from the full path
        filename=$(basename "$file_path")
        
        # Define the full path for the proposed file
        proposed_file_path="$proposed_dir/$filename"
        
        # Save the proposed content to the new file
        echo "$file_content" > "$proposed_file_path"

        # Log this action for observability
        echo "Saved proposed file content to $proposed_file_path" >> "$output_dir/trace.log"

        # --- Future Enhancement: Launch Gemini Review Agent ---
        # The following line is a placeholder for launching the non-interactive Gemini agent.
        # It would need the correct command and context variables.
        # (geminiid "Review the proposed file at $proposed_file_path" --context-vars ... &)
    fi
elif [ "$tool_name" = "Edit" ]; then
    proposed_dir="$output_dir/proposed"
    mkdir -p "$proposed_dir"

    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    old_content=$(echo "$input" | jq -r '.tool_input.old_string // empty')
    new_content=$(echo "$input" | jq -r '.tool_input.new_string // empty')

    if [ -n "$file_path" ] && [ -n "$new_content" ]; then
        filename=$(basename "$file_path")
        proposed_file_path="$proposed_dir/$filename.proposed.md"
        
        # Create markdown content with old and new strings
        {
            echo "# Proposed Edit for \`$filename\`"
            echo ""
            echo "## Original Content"
            echo ""
            echo "\`\`\`"
            echo "$old_content"
            echo "\`\`\`"
            echo ""
            echo "## Proposed New Content"
            echo ""
            echo "\`\`\`"
            echo "$new_content"
            echo "\`\`\`"
        } > "$proposed_file_path"

        echo "Saved proposed edit content to $proposed_file_path" >> "$output_dir/trace.log"
    fi
fi
