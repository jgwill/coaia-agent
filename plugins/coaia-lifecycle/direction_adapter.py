"""Direction normalization adapter for the COAIA ecosystem.

coaia-agent normalizes direction strings to UPPERCASE on write and
accepts any casing on read, per the coaia-package-consumption spec §3.1.

Three casings coexist in the COAIA ecosystem:
  - lowercase: mcp-pde runtime  (e.g. ``"east"``)
  - Title-case: coaia-narrative mmotEvaluations (e.g. ``"East"``)
  - UPPERCASE:  proposed canonical (e.g. ``"EAST"``)

coaia-agent adopts UPPERCASE as the canonical write form and normalizes
on write so downstream consumers (coaia-pde, coaia-narrative,
coaia-visualizer) receive consistent values.
"""

from __future__ import annotations

from typing import Optional

# The four canonical direction values in UPPERCASE (write form).
CANONICAL_DIRECTIONS = frozenset({"EAST", "SOUTH", "WEST", "NORTH"})


def normalize_direction(raw: str) -> str:
    """Normalize a direction string to UPPERCASE canonical form.

    Accepts any casing (lowercase, Title-case, UPPERCASE).  Raises
    ``ValueError`` if the value is not a recognized direction.

    Parameters
    ----------
    raw:
        A direction string in any casing, e.g. ``"east"``, ``"East"``,
        or ``"EAST"``.

    Returns
    -------
    str
        The UPPERCASE canonical direction: ``"EAST"``, ``"SOUTH"``,
        ``"WEST"``, or ``"NORTH"``.

    Raises
    ------
    ValueError
        If ``raw`` is not a recognized direction string.

    Examples
    --------
    >>> normalize_direction("east")
    'EAST'
    >>> normalize_direction("South")
    'SOUTH'
    >>> normalize_direction("WEST")
    'WEST'
    """
    upper = raw.strip().upper()
    if upper not in CANONICAL_DIRECTIONS:
        raise ValueError(
            f"Unknown direction: {raw!r}. "
            f"Expected one of: {sorted(CANONICAL_DIRECTIONS)}"
        )
    return upper


def read_direction(raw: Optional[str]) -> Optional[str]:
    """Normalize a direction string from any input source to UPPERCASE.

    Unlike ``normalize_direction()``, this function accepts ``None`` and
    returns ``None`` for absent values (e.g. entities without a
    ``direction`` field).  Used on the read path when consuming
    DecompositionResult from mcp-pde or MMOT evaluations from
    coaia-narrative.

    Parameters
    ----------
    raw:
        A direction string in any casing, or ``None``.

    Returns
    -------
    str | None
        UPPERCASE canonical direction, or ``None`` if ``raw`` is ``None``
        or empty.
    """
    if not raw:
        return None
    try:
        return normalize_direction(raw)
    except ValueError:
        return None
