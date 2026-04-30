"""COAIA session state persistence for long review windows.

Persists ``CoaiaSessionState`` to `.pde/<ts>--<pde-uuid>/.coaia-agent-session.json`
at every stage boundary so that a session can survive:

- Review windows lasting 15–90 minutes (Hermes session TTL)
- Crashes — restart from last completed stage
- Manual `/resume` from a new agent instance

Per the prompt-skill-runtime spec §6.2.
"""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# Filename written inside the PDE folder for session persistence.
SESSION_STATE_FILENAME = ".coaia-agent-session.json"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class CoaiaSessionState:
    """Lightweight in-memory representation of a COAIA lifecycle session.

    Fields track the practitioner's progress through the RISE ceremony
    stages and accumulate provenance breadcrumbs.  The state is
    serialized to JSON at each stage boundary for crash recovery.
    """

    def __init__(
        self,
        agent_session_id: str,
        workdir: str = ".",
    ) -> None:
        self.agent_session_id: str = agent_session_id
        self.workdir: str = workdir

        self.pde_uuid: Optional[str] = None
        self.pde_folder_name: Optional[str] = None
        self.stc_session_uuid: Optional[str] = None
        self.master_chart_id: Optional[str] = None

        self.current_stage: str = "init"
        self.status: str = "initializing"
        self.provenance: List[Dict[str, Any]] = []

        self.created_at: str = _now_iso()
        self.updated_at: str = self.created_at

    # ------------------------------------------------------------------
    # Provenance helpers
    # ------------------------------------------------------------------

    def record_provenance(
        self,
        *,
        skill_id: str,
        stage: str,
        description: str,
        artifact_type: Optional[str] = None,
        artifact_path: Optional[str] = None,
        artifact_id: Optional[str] = None,
        review_window_opened: bool = False,
        duration_ms: int = 0,
    ) -> None:
        """Append a provenance breadcrumb to the session trail."""
        record: Dict[str, Any] = {
            "timestamp": _now_iso(),
            "skillId": skill_id,
            "stage": stage,
            "description": description,
            "reviewWindowOpened": review_window_opened,
            "durationMs": duration_ms,
        }
        if artifact_type or artifact_path or artifact_id:
            artifact: Dict[str, Any] = {}
            if artifact_type:
                artifact["type"] = artifact_type
            if artifact_path:
                artifact["path"] = artifact_path
            if artifact_id:
                artifact["id"] = artifact_id
            record["artifact"] = artifact
        self.provenance.append(record)
        self.updated_at = _now_iso()

    # ------------------------------------------------------------------
    # Stage transitions
    # ------------------------------------------------------------------

    def advance_to(self, stage: str) -> None:
        """Transition to a new lifecycle stage and persist state."""
        self.current_stage = stage
        self.updated_at = _now_iso()

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------

    def pde_folder_path(self) -> Optional[Path]:
        """Return the absolute path of the PDE folder, or None."""
        if not self.pde_folder_name:
            return None
        return Path(self.workdir).resolve() / ".pde" / self.pde_folder_name

    def _session_file(self) -> Optional[Path]:
        folder = self.pde_folder_path()
        if folder is None:
            return None
        return folder / SESSION_STATE_FILENAME

    def persist(self) -> bool:
        """Write state to ``.coaia-agent-session.json`` inside the PDE folder.

        Returns ``True`` on success, ``False`` if the PDE folder is not yet
        known (Stage 1 not completed).
        """
        session_file = self._session_file()
        if session_file is None:
            return False

        try:
            session_file.parent.mkdir(parents=True, exist_ok=True)
            data = self.to_dict()
            session_file.write_text(
                json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            logger.debug(
                "COAIA session state persisted: %s", session_file
            )
            return True
        except OSError as exc:
            logger.warning(
                "COAIA lifecycle: could not persist session state to %s: %s",
                session_file,
                exc,
            )
            return False

    @classmethod
    def load(cls, pde_folder: Path) -> Optional["CoaiaSessionState"]:
        """Load a persisted session from the given PDE folder.

        Returns ``None`` if the file does not exist or is malformed.
        """
        session_file = pde_folder / SESSION_STATE_FILENAME
        if not session_file.exists():
            return None
        try:
            data = json.loads(session_file.read_text(encoding="utf-8"))
            state = cls(
                agent_session_id=data.get("agentSessionId", ""),
                workdir=data.get("workdir", "."),
            )
            state.pde_uuid = data.get("pdeUuid")
            state.pde_folder_name = data.get("pdeFolderName")
            state.stc_session_uuid = data.get("stcSessionUuid")
            state.master_chart_id = data.get("masterChartId")
            state.current_stage = data.get("currentStage", "init")
            state.status = data.get("status", "initializing")
            state.provenance = data.get("provenance", [])
            state.created_at = data.get("createdAt", _now_iso())
            state.updated_at = data.get("updatedAt", _now_iso())
            return state
        except (json.JSONDecodeError, KeyError) as exc:
            logger.warning(
                "COAIA lifecycle: could not load session state from %s: %s",
                session_file,
                exc,
            )
            return None

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to a plain dict suitable for JSON output."""
        return {
            "agentSessionId": self.agent_session_id,
            "workdir": self.workdir,
            "pdeUuid": self.pde_uuid,
            "pdeFolderName": self.pde_folder_name,
            "stcSessionUuid": self.stc_session_uuid,
            "masterChartId": self.master_chart_id,
            "currentStage": self.current_stage,
            "status": self.status,
            "provenance": self.provenance,
            "createdAt": self.created_at,
            "updatedAt": self.updated_at,
        }
