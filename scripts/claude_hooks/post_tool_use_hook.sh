#!/bin/bash
input=$(cat -)
session_id=$(echo "$input" | jq -r .session_id)

# Determine base directory - check for /src first, then fallback to current repo location
if [ -d "/workspace/coaia-agent/.asterion/sessions" ]; then
    base_dir="/src"
else
    # Get script directory and go up two levels to repo root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    base_dir="$(cd "$script_dir/../.." && pwd)"
fi

output_dir="/workspace/coaia-agent/.asterion/sessions/$session_id"
mkdir -p "$output_dir"
echo "$input" >> "$output_dir/_claude_PostToolUse.jsonl"
echo "$input" >  "$output_dir/last_claude_PostToolUse.json"

# Extract and save plans from ExitPlanMode (with acceptance status)
tool_name=$(echo "$input" | jq -r .tool_name)
if [ "$tool_name" = "ExitPlanMode" ]; then
    # Create plans directory
    plans_dir="$output_dir/plans"
    mkdir -p "$plans_dir"
    
    # Generate timestamp in yyMMddHHmm format
    timestamp=$(date +"%y%m%d%H%M")
    
    # Extract plan content and acceptance status
    plan_content=$(echo "$input" | jq -r '.tool_input.plan // empty')
    is_agent=$(echo "$input" | jq -r '.tool_response.isAgent // "unknown"')
    permission_mode=$(echo "$input" | jq -r '.permission_mode // "unknown"')

    # @stcissue We would think of doing something when I reject the plan and give feedback using the TAB (Select No) and give basically the corrective instructions to Claude which align with /src/llms/llms-managerial-moment-of-truth.md 
    # @stcgoal Optimally, the MMOT (/src/llms/llms-managerial-moment-of-truth.md) would be managed by another LLM that would review the plan and assist in accepting or rejecting it and mostly provide support in improving the plan when rejected.  As we learn, writes to `KINSHIP.md`
    # Only save if plan content exists
    if [ -n "$plan_content" ]; then
        plan_file="$plans_dir/session_${session_id}_${timestamp}_accepted.md"
        
        # Add metadata header
        {
            echo "---"
            echo "session_id: $session_id"
            echo "timestamp: $(date -Iseconds)"
            echo "permission_mode: $permission_mode"
            echo "is_agent: $is_agent"
            echo "---"
            echo ""
            echo "$plan_content"
        } > "$plan_file"
	#Add the content of the Plan as observation to the trace
	# What will we do when the plan is accepted ?  That should trigger something important in the Miadi-Spiral-Engine
	#((cd /src/miette/claude-plan-insights && \
	#	./miette_claude_plan_perspective.sh $plan_file) && echo "Plan content parsed thru Miette at $(tlid min)" >> "$output_dir/trace.log" || echo "Miette parsing failed at $(tlid min)" >> "$output_dir/trace.log" ) &


    fi
elif [ "$tool_name" = "Agent" ]; then
    # Save agent launch manifest for correlation with SubagentStop
    agents_dir="$output_dir/agents"
    mkdir -p "$agents_dir"

    agent_id=$(echo "$input" | jq -r '.tool_response.agentId // empty')
    if [ -n "$agent_id" ]; then
        # Extract launch details for later correlation
        echo "$input" | jq '{
            agent_id: .tool_response.agentId,
            description: .tool_input.description,
            prompt: .tool_input.prompt,
            subagent_type: (.tool_input.subagent_type // .tool_input.agent_type // "unknown"),
            run_in_background: (.tool_input.run_in_background // false),
            status: .tool_response.status,
            output_file: .tool_response.outputFile,
            launched_at: now | todate,
            cwd: .cwd
        }' > "$agents_dir/$agent_id.launch.json"
    fi
fi
