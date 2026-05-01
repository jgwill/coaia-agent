"""Source provenance adapter for the COAIA ecosystem.

Every entity that coaia-agent produces directly must carry a
``metadata.source`` sub-object so downstream consumers can distinguish
between production paths (coaia-agent, coaia-pde, coaia-planning,
coaia-narrative, mcp-pde, or manual).

Per the coaia-package-consumption spec §3.2 and the
schema-evolution-and-ecosystem-metadata spec §4.
"""

from __future__ import annotations

from datetime import datetime as _dt, timezone
from typing import Dict, Optional, Any


# Valid system values for the source.system field.
VALID_SYSTEMS = frozenset({
    "coaia-agent",
    "coaia-pde",
    "coaia-planning",
    "coaia-narrative",
    "mcp-pde",
    "manual",
})


def make_source_provenance(
    system: str = "coaia-agent",
    version: Optional[str] = None,
    tool_name: Optional[str] = None,
    session_id: Optional[str] = None,
    created_at: Optional[str] = None,
) -> Dict[str, Any]:
    """Return a ``metadata.source`` provenance sub-object.

    Parameters
    ----------
    system:
        The producing system.  One of the values in ``VALID_SYSTEMS``.
        Defaults to ``"coaia-agent"`` for entities produced directly by
        coaia-agent.
    version:
        Optional version string of the producing system or skill.
    tool_name:
        The MCP tool or skill name that created this entity, if
        applicable (e.g. ``"pde_decompose"``, ``"create_stc"``).
    session_id:
        The PDE session UUID, if this entity belongs to a PDE session.
    created_at:
        ISO-8601 creation timestamp.  Defaults to the current UTC time.

    Returns
    -------
    dict
        A dict suitable for use as ``entity["metadata"]["source"]``.

    Examples
    --------
    >>> src = make_source_provenance(tool_name="pde_decompose")
    >>> src["system"]
    'coaia-agent'
    >>> "createdAt" in src
    True
    """
    if system not in VALID_SYSTEMS:
        raise ValueError(
            f"Unknown system: {system!r}. "
            f"Expected one of: {sorted(VALID_SYSTEMS)}"
        )

    if created_at is None:
        created_at = _dt.now(timezone.utc).isoformat()

    record: Dict[str, Any] = {
        "system": system,
        "createdAt": created_at,
    }
    if version is not None:
        record["version"] = version
    if tool_name is not None:
        record["toolName"] = tool_name
    if session_id is not None:
        record["sessionId"] = session_id

    return record


def inject_provenance(
    entity: Dict[str, Any],
    *,
    system: str = "coaia-agent",
    tool_name: Optional[str] = None,
    session_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Add ``metadata.source`` to an entity dict in-place and return it.

    If the entity already has ``metadata.source``, the existing value is
    preserved (coaia-agent does not override provenance set by delegating
    packages such as coaia-pde).

    Parameters
    ----------
    entity:
        The entity dict to annotate.
    system:
        The producing system.  Defaults to ``"coaia-agent"``.
    tool_name:
        MCP tool or skill that created this entity, if applicable.
    session_id:
        PDE session UUID, if applicable.

    Returns
    -------
    dict
        The same ``entity`` dict, with ``metadata.source`` set.
    """
    metadata = entity.setdefault("metadata", {})
    if "source" not in metadata:
        metadata["source"] = make_source_provenance(
            system=system,
            tool_name=tool_name,
            session_id=session_id,
        )
    return entity
