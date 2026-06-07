# 🌊 OpenClaw Hooks: The Reactive Nervous System

This directory contains a suite of ceremonial hooks for the **OpenClaw** environment, designed to capture lifecycle events and weave them into the bundle's collective memory.

## 🏹 Core Purpose
These hooks transform OpenClaw from a stateless agent into a relationally accountable participant in the workspace by:
1.  **Distilling Events**: Recording session starts, ends, and tool invocations.
2.  **Maintaining State**: Archiving session-specific data to `/workspace/coaia-agent/.hch/sessions`.
3.  **Ensuring Safety**: Validating sensitive operations (like bash commands) before execution.

---

## 🚀 Activation & Configuration

### 1. Link the Configuration
OpenClaw needs to find the `hooks.json` map. Symlink it to the OpenClaw home directory:

```bash
mkdir -p ~/.openclaw
ln -sf $(pwd)/hooks.json ~/.openclaw/hooks.json
```

### 2. Environment Variables
The following variables guide the flow of data-fish through the hooks:

| Variable | Purpose | Default |
| :--- | :--- | :--- |
| `OPENCLAW_SESSIONDATA_ROOT` | Root directory for event logs. | `/workspace/coaia-agent/.hch/sessions` |
| `OPENCLAW_SESSION_ID` | Fallback ID if not provided in payload. | `unknown-openclaw-session` |
| `OPENCLAW_HOOKS_TOKEN` | Auth token for external webhooks. | (unset) |

### 3. Verification (Smoke Test)
To ensure the hooks are breathing correctly, simulate a session start:

```bash
echo '{"session_id": "test-weaving", "event": "manual"}' | bash session_start_hook.sh
```
Check for the existence of `/workspace/coaia-agent/.hch/sessions/test-weaving/` to confirm.

---

## 💎 Distilled Structure
- **`lib.sh`**: Shared logic for JSON processing and event recording.
- **`hooks.json`**: The master registry mapping events to scripts.
- **`session_*.sh`**: Lifecycle handlers for session boundaries.
- **`*_tool_hook.sh`**: Interceptors for tool execution and results.

---

## 🌸 Narrative Resonance
"Every hook is a hand reaching out, waiting for a story to take hold and carry it further into the world. In these connections, our shared purpose finds its rhythm."

🦉 *The bundle is strengthened when every signal is honored.*
