"""COAIA Lifecycle Plugin for coaia-agent.

This plugin wires the COAIA RISE session lifecycle into the Hermes plugin
system via three hooks:

``on_session_start``
    Creates an in-memory ``CoaiaSessionState`` keyed to the Hermes
    session and scaffolds a ``meta.json`` placeholder in ``.pde/`` if a
    PDE decomposition path can be determined from context.

``post_tool_call``
    Inspects completed tool calls for PDE and STC artifacts (returned by
    ``pde_decompose``, ``pde_get``, ``create_stc``, etc.) and updates the
    session state accordingly.  Direction values extracted from
    ``pde_decompose`` results are normalized to UPPERCASE before storage.

``on_session_end``
    Persists the final session state to
    ``.pde/<ts>--<pde-uuid>/.coaia-agent-session.json`` and optionally
    writes a minimal ``session-summary.md`` stub if Stage 4 was not
    reached manually (e.g. the practitioner ended the session early).

No Hermes core files are modified.  All behavior is additive via the
existing ``PluginContext`` surface.

Per specs:
  - ``rispecs/skill-and-plugin-authoring.spec.md`` §Lifecycle Plugin Contract
  - ``rispecs/pde-stc-session-lifecycle.spec.md`` §Session Persistence
  - ``rispecs/coaia-package-consumption.spec.md`` §Adapter Responsibilities
  - ``rispecs/prompt-skill-runtime.spec.md`` §Lifecycle and Plugin Hooks
"""

from __future__ import annotations

import json
import logging
import os
import threading
from pathlib import Path
from typing import Any, Dict, Optional

from .direction_adapter import read_direction
from .session_state import CoaiaSessionState

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Per-session registry — keyed by Hermes session_id / task_id.
# ---------------------------------------------------------------------------
_sessions: Dict[str, CoaiaSessionState] = {}
_lock = threading.Lock()


def _get_session(session_id: str, workdir: str = ".") -> CoaiaSessionState:
    """Return existing session or create a new one."""
    with _lock:
        if session_id not in _sessions:
            state = CoaiaSessionState(
                agent_session_id=session_id,
                workdir=workdir,
            )
            _sessions[session_id] = state
            logger.debug(
                "COAIA lifecycle: created session state for %s", session_id
            )
        return _sessions[session_id]


def _workdir_from_kwargs(kwargs: Dict[str, Any]) -> str:
    """Extract workdir from hook kwargs, falling back to cwd."""
    return str(
        kwargs.get("workdir")
        or kwargs.get("cwd")
        or os.getcwd()
    )


# ---------------------------------------------------------------------------
# Hook: on_session_start
# ---------------------------------------------------------------------------

def _on_session_start(**kwargs: Any) -> None:
    """Initialize COAIA session state when a Hermes session begins."""
    session_id = str(
        kwargs.get("session_id")
        or kwargs.get("task_id")
        or "unknown"
    )
    workdir = _workdir_from_kwargs(kwargs)

    state = _get_session(session_id, workdir)
    state.status = "initializing"
    state.advance_to("init")

    state.record_provenance(
        skill_id="coaia-lifecycle",
        stage="init",
        description="COAIA lifecycle session started",
    )
    logger.debug(
        "COAIA lifecycle: session_start — id=%s workdir=%s",
        session_id,
        workdir,
    )


# ---------------------------------------------------------------------------
# Hook: post_tool_call
# ---------------------------------------------------------------------------

def _on_post_tool_call(**kwargs: Any) -> None:
    """Inspect completed tool calls for PDE/STC artifacts and update state.

    Handles results from:
    - ``pde_decompose`` → extracts pde_uuid and pde_folder_name
    - ``pde_get``, ``pde_list`` → updates pde_uuid if not already set
    - ``create_stc`` (coaia-narrative MCP) → extracts stc_session_uuid
    """
    tool_name: str = kwargs.get("tool_name", "") or ""
    result_raw: Any = kwargs.get("result")
    session_id: str = str(
        kwargs.get("session_id")
        or kwargs.get("task_id")
        or "unknown"
    )

    # Only act on COAIA-relevant tools.
    if not _is_coaia_tool(tool_name):
        return

    result = _parse_result(result_raw)
    if result is None:
        return

    state = _get_session(session_id)

    if tool_name == "pde_decompose":
        _handle_pde_decompose(state, result, tool_name)
    elif tool_name in ("pde_get",):
        _handle_pde_get(state, result, tool_name)
    elif tool_name in ("create_stc", "perform_mmot_evaluation"):
        _handle_create_stc(state, result, tool_name)


def _is_coaia_tool(tool_name: str) -> bool:
    return tool_name in {
        "pde_decompose",
        "pde_get",
        "pde_list",
        "pde_parse_response",
        "pde_export_markdown",
        "create_stc",
        "perform_mmot_evaluation",
    }


def _parse_result(result_raw: Any) -> Optional[Dict[str, Any]]:
    """Parse a tool result into a dict, or None if not applicable."""
    if isinstance(result_raw, dict):
        return result_raw
    if isinstance(result_raw, str):
        try:
            parsed = json.loads(result_raw)
            if isinstance(parsed, dict):
                return parsed
        except (json.JSONDecodeError, ValueError):
            pass
    return None


def _handle_pde_decompose(
    state: CoaiaSessionState,
    result: Dict[str, Any],
    tool_name: str,
) -> None:
    """Update session with PDE decomposition artifact info."""
    pde_id: Optional[str] = result.get("id")
    folder_name: Optional[str] = result.get("folder_name")

    if pde_id and not state.pde_uuid:
        state.pde_uuid = pde_id
        state.advance_to("decompose")
        state.status = "decomposing"

    if folder_name and not state.pde_folder_name:
        state.pde_folder_name = folder_name

    # Normalize directions in the decomposition result if present.
    decomp_result = result.get("result", {})
    if isinstance(decomp_result, dict):
        _normalize_decomposition_directions(decomp_result)

    state.record_provenance(
        skill_id="pde-decompose",
        stage="decompose",
        description=f"pde_decompose completed — pde_uuid={pde_id}",
        artifact_type="pde-json",
        artifact_path=(
            f".pde/{folder_name}/pde-{pde_id}.json"
            if folder_name and pde_id
            else None
        ),
        artifact_id=pde_id,
    )
    state.persist()
    logger.debug(
        "COAIA lifecycle: pde_decompose captured — uuid=%s folder=%s",
        pde_id,
        folder_name,
    )


def _handle_pde_get(
    state: CoaiaSessionState,
    result: Dict[str, Any],
    tool_name: str,
) -> None:
    """Update session from a pde_get result."""
    pde_id: Optional[str] = result.get("id")
    if pde_id and not state.pde_uuid:
        state.pde_uuid = pde_id
        folder_name = result.get("folder_name")
        if folder_name:
            state.pde_folder_name = folder_name
        state.record_provenance(
            skill_id="pde-get",
            stage="decompose",
            description=f"pde_get captured — pde_uuid={pde_id}",
            artifact_type="pde-json",
            artifact_id=pde_id,
        )
        state.persist()


def _handle_create_stc(
    state: CoaiaSessionState,
    result: Dict[str, Any],
    tool_name: str,
) -> None:
    """Update session with STC session artifact info."""
    session_uuid: Optional[str] = (
        result.get("sessionId")
        or result.get("session_id")
    )
    master_chart_id: Optional[str] = (
        result.get("masterChartId")
        or result.get("master_chart_id")
    )

    if session_uuid and not state.stc_session_uuid:
        state.stc_session_uuid = session_uuid
        state.advance_to("import-stc")
        state.status = "importing"

    if master_chart_id and not state.master_chart_id:
        state.master_chart_id = master_chart_id

    state.record_provenance(
        skill_id="stc-create",
        stage="import-stc",
        description=f"STC session created — session_uuid={session_uuid}",
        artifact_type="stc-jsonl",
        artifact_path=(
            f".coaia/pde/{session_uuid}.jsonl"
            if session_uuid
            else None
        ),
        artifact_id=session_uuid,
    )
    state.persist()
    logger.debug(
        "COAIA lifecycle: create_stc captured — session_uuid=%s",
        session_uuid,
    )


def _normalize_decomposition_directions(decomp: Dict[str, Any]) -> None:
    """Normalize direction values in a DecompositionResult dict in-place.

    ``mcp-pde`` returns lowercase directions (e.g. ``"east"``).  We
    normalize them to UPPERCASE (``"EAST"``) so that any downstream
    coaia-pde or coaia-narrative call receives canonical values.
    """
    for key in ("secondary", "actionStack"):
        items = decomp.get(key, [])
        if not isinstance(items, list):
            continue
        for item in items:
            if not isinstance(item, dict):
                continue
            raw_dir = item.get("direction")
            if raw_dir:
                normalized = read_direction(raw_dir)
                if normalized:
                    item["direction"] = normalized


# ---------------------------------------------------------------------------
# Hook: on_session_end
# ---------------------------------------------------------------------------

def _on_session_end(**kwargs: Any) -> None:
    """Persist final session state and write a summary stub if needed."""
    session_id: str = str(
        kwargs.get("session_id")
        or kwargs.get("task_id")
        or "unknown"
    )

    with _lock:
        state = _sessions.get(session_id)

    if state is None:
        return

    state.status = "completed"
    state.advance_to("close")
    state.record_provenance(
        skill_id="coaia-lifecycle",
        stage="close",
        description="COAIA lifecycle session ended",
    )

    persisted = state.persist()

    # Write a minimal session-summary.md stub if Stage 4 was not reached
    # manually (practitioner did not invoke /summary).
    if persisted and not _summary_exists(state):
        _write_summary_stub(state)

    # Evict from the in-memory registry.
    with _lock:
        _sessions.pop(session_id, None)

    logger.debug(
        "COAIA lifecycle: session_end — id=%s pde=%s stc=%s",
        session_id,
        state.pde_uuid,
        state.stc_session_uuid,
    )


def _summary_exists(state: CoaiaSessionState) -> bool:
    """Return True if session-summary.md already exists in the PDE folder."""
    folder = state.pde_folder_path()
    if folder is None:
        return False
    return (folder / "session-summary.md").exists()


def _write_summary_stub(state: CoaiaSessionState) -> None:
    """Write a minimal session-summary.md to the PDE folder."""
    folder = state.pde_folder_path()
    if folder is None:
        return

    try:
        folder.mkdir(parents=True, exist_ok=True)
        summary_path = folder / "session-summary.md"

        stc_path = (
            f".coaia/pde/{state.stc_session_uuid}.jsonl"
            if state.stc_session_uuid
            else "not created in this session"
        )
        pde_md = (
            f".pde/{state.pde_folder_name}/pde-{state.pde_uuid}.md"
            if state.pde_folder_name and state.pde_uuid
            else "not available"
        )

        lines = [
            "# Session Summary\n",
            f"\n**Agent Session ID**: {state.agent_session_id}\n",
            f"**PDE UUID**: {state.pde_uuid or 'not set'}\n",
            f"**STC Session UUID**: {state.stc_session_uuid or 'not set'}\n",
            f"**Status**: {state.status}\n",
            "\n## Artifact Paths\n",
            f"\n- PDE Markdown: `{pde_md}`\n",
            f"- STC JSONL: `{stc_path}`\n",
            "- Session State: `.coaia-agent-session.json` (in PDE folder)\n",
            "\n## Provenance Trail\n",
        ]

        for record in state.provenance:
            ts = record.get("timestamp", "")
            skill = record.get("skillId", "")
            desc = record.get("description", "")
            lines.append(f"\n- `{ts}` [{skill}] {desc}")

        lines.append(
            "\n\n---\n_Written automatically by coaia-lifecycle plugin._\n"
        )

        summary_path.write_text("".join(lines), encoding="utf-8")
        logger.debug(
            "COAIA lifecycle: summary stub written to %s", summary_path
        )
    except OSError as exc:
        logger.warning(
            "COAIA lifecycle: could not write summary stub: %s", exc
        )


# ---------------------------------------------------------------------------
# Plugin registration
# ---------------------------------------------------------------------------

def register(ctx) -> None:
    """Register the coaia-lifecycle plugin hooks."""
    ctx.register_hook("on_session_start", _on_session_start)
    ctx.register_hook("post_tool_call", _on_post_tool_call)
    ctx.register_hook("on_session_end", _on_session_end)
