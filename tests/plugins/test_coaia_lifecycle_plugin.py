"""Tests for the coaia-lifecycle plugin.

Covers:
  * ``direction_adapter``: normalize_direction / read_direction
  * ``provenance``: make_source_provenance / inject_provenance
  * ``session_state``: CoaiaSessionState persistence and serialization
  * Plugin ``__init__``: hook dispatch, tool result capture, summary stub,
    plugin registration via PluginContext
"""

from __future__ import annotations

import importlib
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any

import pytest


# ---------------------------------------------------------------------------
# Helpers — dynamic import from repo paths so tests work without install
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]
PLUGIN_DIR = REPO_ROOT / "plugins" / "coaia-lifecycle"


def _load(module_name: str, file_name: str):
    """Load a module from the plugin directory by filename."""
    path = PLUGIN_DIR / file_name
    spec = importlib.util.spec_from_file_location(module_name, path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def direction_adapter():
    return _load("direction_adapter_under_test", "direction_adapter.py")


@pytest.fixture(scope="module")
def provenance_mod():
    return _load("provenance_under_test", "provenance.py")


@pytest.fixture(scope="module")
def session_state_mod():
    _load("direction_adapter_under_test", "direction_adapter.py")
    return _load("session_state_under_test", "session_state.py")


# ---------------------------------------------------------------------------
# direction_adapter tests
# ---------------------------------------------------------------------------


class TestNormalizeDirection:
    def test_lowercase(self, direction_adapter):
        assert direction_adapter.normalize_direction("east") == "EAST"
        assert direction_adapter.normalize_direction("south") == "SOUTH"
        assert direction_adapter.normalize_direction("west") == "WEST"
        assert direction_adapter.normalize_direction("north") == "NORTH"

    def test_title_case(self, direction_adapter):
        assert direction_adapter.normalize_direction("East") == "EAST"
        assert direction_adapter.normalize_direction("South") == "SOUTH"
        assert direction_adapter.normalize_direction("West") == "WEST"
        assert direction_adapter.normalize_direction("North") == "NORTH"

    def test_uppercase(self, direction_adapter):
        assert direction_adapter.normalize_direction("EAST") == "EAST"

    def test_strips_whitespace(self, direction_adapter):
        assert direction_adapter.normalize_direction("  east  ") == "EAST"

    def test_invalid_raises(self, direction_adapter):
        with pytest.raises(ValueError, match="Unknown direction"):
            direction_adapter.normalize_direction("up")

    def test_invalid_empty_raises(self, direction_adapter):
        with pytest.raises(ValueError):
            direction_adapter.normalize_direction("")


class TestReadDirection:
    def test_none_returns_none(self, direction_adapter):
        assert direction_adapter.read_direction(None) is None

    def test_empty_string_returns_none(self, direction_adapter):
        assert direction_adapter.read_direction("") is None

    def test_valid_normalizes(self, direction_adapter):
        assert direction_adapter.read_direction("east") == "EAST"

    def test_invalid_returns_none(self, direction_adapter):
        assert direction_adapter.read_direction("diagonal") is None


# ---------------------------------------------------------------------------
# provenance tests
# ---------------------------------------------------------------------------


class TestMakeSourceProvenance:
    def test_defaults(self, provenance_mod):
        src = provenance_mod.make_source_provenance()
        assert src["system"] == "coaia-agent"
        assert "createdAt" in src
        assert "version" not in src
        assert "toolName" not in src

    def test_tool_name(self, provenance_mod):
        src = provenance_mod.make_source_provenance(tool_name="pde_decompose")
        assert src["toolName"] == "pde_decompose"

    def test_session_id(self, provenance_mod):
        src = provenance_mod.make_source_provenance(session_id="abc-123")
        assert src["sessionId"] == "abc-123"

    def test_valid_systems(self, provenance_mod):
        for system in provenance_mod.VALID_SYSTEMS:
            src = provenance_mod.make_source_provenance(system=system)
            assert src["system"] == system

    def test_invalid_system_raises(self, provenance_mod):
        with pytest.raises(ValueError, match="Unknown system"):
            provenance_mod.make_source_provenance(system="unknown-package")


class TestInjectProvenance:
    def test_sets_metadata_source(self, provenance_mod):
        entity: dict = {}
        result = provenance_mod.inject_provenance(entity)
        assert "metadata" in result
        assert "source" in result["metadata"]
        assert result["metadata"]["source"]["system"] == "coaia-agent"

    def test_does_not_override_existing_source(self, provenance_mod):
        entity = {"metadata": {"source": {"system": "coaia-pde"}}}
        result = provenance_mod.inject_provenance(entity)
        assert result["metadata"]["source"]["system"] == "coaia-pde"

    def test_preserves_other_metadata(self, provenance_mod):
        entity = {"metadata": {"direction": "EAST"}}
        result = provenance_mod.inject_provenance(entity)
        assert result["metadata"]["direction"] == "EAST"
        assert "source" in result["metadata"]


# ---------------------------------------------------------------------------
# session_state tests
# ---------------------------------------------------------------------------


class TestCoaiaSessionState:
    def test_initial_state(self, session_state_mod):
        state = session_state_mod.CoaiaSessionState("sess-001")
        assert state.agent_session_id == "sess-001"
        assert state.pde_uuid is None
        assert state.stc_session_uuid is None
        assert state.current_stage == "init"
        assert state.status == "initializing"
        assert state.provenance == []

    def test_record_provenance(self, session_state_mod):
        state = session_state_mod.CoaiaSessionState("sess-002")
        state.record_provenance(
            skill_id="pde-decompose",
            stage="decompose",
            description="test provenance",
        )
        assert len(state.provenance) == 1
        rec = state.provenance[0]
        assert rec["skillId"] == "pde-decompose"
        assert rec["stage"] == "decompose"
        assert rec["description"] == "test provenance"
        assert "timestamp" in rec

    def test_advance_to(self, session_state_mod):
        state = session_state_mod.CoaiaSessionState("sess-003")
        state.advance_to("decompose")
        assert state.current_stage == "decompose"

    def test_to_dict_round_trip(self, session_state_mod):
        state = session_state_mod.CoaiaSessionState("sess-004")
        state.pde_uuid = "test-pde-uuid"
        d = state.to_dict()
        assert d["agentSessionId"] == "sess-004"
        assert d["pdeUuid"] == "test-pde-uuid"
        # Serializable to JSON
        json.dumps(d)

    def test_persist_returns_false_without_pde_folder(self, session_state_mod, tmp_path):
        state = session_state_mod.CoaiaSessionState("sess-005", workdir=str(tmp_path))
        # pde_folder_name not set
        result = state.persist()
        assert result is False

    def test_persist_and_load(self, session_state_mod, tmp_path):
        state = session_state_mod.CoaiaSessionState("sess-006", workdir=str(tmp_path))
        state.pde_uuid = "abc-123"
        state.pde_folder_name = "2604291200--abc-123"
        state.stc_session_uuid = "stc-789"
        state.record_provenance(
            skill_id="pde-decompose",
            stage="decompose",
            description="persisted",
        )

        result = state.persist()
        assert result is True

        pde_folder = tmp_path / ".pde" / "2604291200--abc-123"
        assert (pde_folder / ".coaia-agent-session.json").exists()

        loaded = session_state_mod.CoaiaSessionState.load(pde_folder)
        assert loaded is not None
        assert loaded.agent_session_id == "sess-006"
        assert loaded.pde_uuid == "abc-123"
        assert loaded.stc_session_uuid == "stc-789"
        assert len(loaded.provenance) == 1

    def test_load_returns_none_when_file_missing(self, session_state_mod, tmp_path):
        result = session_state_mod.CoaiaSessionState.load(tmp_path)
        assert result is None

    def test_load_returns_none_on_malformed_json(self, session_state_mod, tmp_path):
        bad_file = tmp_path / ".coaia-agent-session.json"
        bad_file.write_text("{not valid json}", encoding="utf-8")
        result = session_state_mod.CoaiaSessionState.load(tmp_path)
        assert result is None


# ---------------------------------------------------------------------------
# Plugin __init__ tests (hooks + summary stub)
# ---------------------------------------------------------------------------


class _FakePluginContext:
    """Minimal PluginContext stub for testing plugin registration."""

    def __init__(self):
        self.hooks: dict = {}
        self.commands: dict = {}

    def register_hook(self, name: str, fn) -> None:
        self.hooks.setdefault(name, []).append(fn)

    def register_command(self, name: str, *, handler, description: str = "") -> None:
        self.commands[name] = handler


@pytest.fixture
def plugin_mod(session_state_mod):
    """Load plugin __init__.py, injecting the already-loaded sub-modules."""
    # Ensure sub-modules are in sys.modules under the names the plugin imports.
    sys.modules["direction_adapter_under_test"] = sys.modules.get(
        "direction_adapter_under_test"
    )

    path = PLUGIN_DIR / "__init__.py"
    spec = importlib.util.spec_from_file_location("coaia_lifecycle_under_test", path)
    mod = importlib.util.module_from_spec(spec)

    # Patch sub-module imports the plugin __init__ does relative-style
    # by pre-populating sys.modules with our already-loaded fixtures.
    import types

    pkg = types.ModuleType("coaia_lifecycle_pkg")
    pkg.direction_adapter = sys.modules.get("direction_adapter_under_test")
    pkg.session_state = sys.modules.get("session_state_under_test")

    # Monkey-patch the loader to inject the package namespace
    original_exec = spec.loader.exec_module

    def patched_exec(m):
        # Replace relative imports in __init__.py by pre-setting attributes
        m.__package__ = "coaia_lifecycle_pkg"
        sys.modules["coaia_lifecycle_pkg"] = pkg
        sys.modules["coaia_lifecycle_pkg.direction_adapter"] = pkg.direction_adapter
        sys.modules["coaia_lifecycle_pkg.session_state"] = pkg.session_state
        original_exec(m)

    spec.loader.exec_module = patched_exec
    sys.modules["coaia_lifecycle_under_test"] = mod
    spec.loader.exec_module(mod)
    return mod


class TestPluginRegistration:
    def test_register_wires_three_hooks(self, plugin_mod):
        ctx = _FakePluginContext()
        plugin_mod.register(ctx)
        assert "on_session_start" in ctx.hooks
        assert "post_tool_call" in ctx.hooks
        assert "on_session_end" in ctx.hooks


class TestOnSessionStart:
    def test_creates_session_state(self, plugin_mod):
        plugin_mod._on_session_start(session_id="s1", workdir="/tmp")
        with plugin_mod._lock:
            assert "s1" in plugin_mod._sessions
        # Cleanup
        plugin_mod._sessions.pop("s1", None)

    def test_unknown_session_id(self, plugin_mod):
        # Should not raise even with missing kwargs
        plugin_mod._on_session_start()
        plugin_mod._sessions.pop("unknown", None)


class TestPostToolCall:
    def test_pde_decompose_updates_state(self, plugin_mod):
        plugin_mod._on_session_start(session_id="s2")
        result = {
            "id": "pde-abc",
            "folder_name": "2604291200--pde-abc",
            "result": {
                "secondary": [{"direction": "east", "text": "action"}],
                "actionStack": [],
            },
        }
        plugin_mod._on_post_tool_call(
            tool_name="pde_decompose",
            result=json.dumps(result),
            session_id="s2",
        )
        with plugin_mod._lock:
            state = plugin_mod._sessions.get("s2")
        assert state is not None
        assert state.pde_uuid == "pde-abc"
        assert state.pde_folder_name == "2604291200--pde-abc"
        plugin_mod._sessions.pop("s2", None)

    def test_pde_decompose_normalizes_directions_in_dict_result(self, plugin_mod):
        """When the result is passed as a dict (not JSON string), directions are
        normalized in-place on the parsed dict by the adapter."""
        plugin_mod._on_session_start(session_id="s2b")
        # Pass as dict — normalization happens in-place on this object.
        result = {
            "id": "pde-xyz",
            "folder_name": "2604291200--pde-xyz",
            "result": {
                "secondary": [{"direction": "east", "text": "action"}],
                "actionStack": [{"direction": "south", "text": "other"}],
            },
        }
        plugin_mod._on_post_tool_call(
            tool_name="pde_decompose",
            result=result,
            session_id="s2b",
        )
        # The dict was normalized in-place.
        assert result["result"]["secondary"][0]["direction"] == "EAST"
        assert result["result"]["actionStack"][0]["direction"] == "SOUTH"
        plugin_mod._sessions.pop("s2b", None)

    def test_pde_decompose_with_json_string_result_captures_uuid(self, plugin_mod):
        """When result is a JSON string, pde_uuid is captured from the parsed dict.

        Direction normalization happens on the parsed dict inside the plugin;
        the original string is unchanged (strings are immutable in Python).
        The important postcondition is that session state captures pde_uuid.
        """
        plugin_mod._on_session_start(session_id="s2c")
        result_str = json.dumps({
            "id": "pde-str",
            "folder_name": "2604291200--pde-str",
            "result": {
                "secondary": [{"direction": "east", "text": "action"}],
                "actionStack": [],
            },
        })
        plugin_mod._on_post_tool_call(
            tool_name="pde_decompose",
            result=result_str,
            session_id="s2c",
        )
        with plugin_mod._lock:
            state = plugin_mod._sessions.get("s2c")
        assert state is not None
        assert state.pde_uuid == "pde-str"
        assert state.pde_folder_name == "2604291200--pde-str"
        plugin_mod._sessions.pop("s2c", None)

    def test_non_coaia_tool_ignored(self, plugin_mod):
        plugin_mod._on_session_start(session_id="s3")
        # Should not raise and should not update state
        plugin_mod._on_post_tool_call(
            tool_name="web_search",
            result='{"results": []}',
            session_id="s3",
        )
        with plugin_mod._lock:
            state = plugin_mod._sessions.get("s3")
        assert state is not None
        assert state.pde_uuid is None
        plugin_mod._sessions.pop("s3", None)

    def test_create_stc_updates_state(self, plugin_mod):
        plugin_mod._on_session_start(session_id="s4")
        result = {
            "sessionId": "stc-xyz",
            "masterChartId": "chart-001",
            "pdeDecompositionId": "pde-abc",
        }
        plugin_mod._on_post_tool_call(
            tool_name="create_stc",
            result=result,
            session_id="s4",
        )
        with plugin_mod._lock:
            state = plugin_mod._sessions.get("s4")
        assert state.stc_session_uuid == "stc-xyz"
        assert state.master_chart_id == "chart-001"
        plugin_mod._sessions.pop("s4", None)


class TestOnSessionEnd:
    def test_evicts_session(self, plugin_mod):
        plugin_mod._on_session_start(session_id="s5")
        plugin_mod._on_session_end(session_id="s5")
        with plugin_mod._lock:
            assert "s5" not in plugin_mod._sessions

    def test_writes_summary_stub(self, plugin_mod, tmp_path):
        plugin_mod._on_session_start(session_id="s6", workdir=str(tmp_path))
        with plugin_mod._lock:
            state = plugin_mod._sessions["s6"]
            state.pde_uuid = "pde-000"
            state.pde_folder_name = "2604291200--pde-000"

        plugin_mod._on_session_end(session_id="s6")

        summary_path = (
            tmp_path / ".pde" / "2604291200--pde-000" / "session-summary.md"
        )
        assert summary_path.exists()
        content = summary_path.read_text(encoding="utf-8")
        assert "Agent Session ID" in content
        assert "coaia-lifecycle" in content

    def test_skips_summary_if_already_exists(self, plugin_mod, tmp_path):
        plugin_mod._on_session_start(session_id="s7", workdir=str(tmp_path))
        with plugin_mod._lock:
            state = plugin_mod._sessions["s7"]
            state.pde_uuid = "pde-111"
            state.pde_folder_name = "2604291200--pde-111"

        # Pre-create summary
        folder = tmp_path / ".pde" / "2604291200--pde-111"
        folder.mkdir(parents=True, exist_ok=True)
        existing = folder / "session-summary.md"
        existing.write_text("# Pre-existing summary\n", encoding="utf-8")

        plugin_mod._on_session_end(session_id="s7")

        # File must not be overwritten
        assert existing.read_text(encoding="utf-8") == "# Pre-existing summary\n"


# ---------------------------------------------------------------------------
# COAIA skills frontmatter validation
# ---------------------------------------------------------------------------


EXPECTED_SKILLS = [
    "pde-decompose.md",
    "stc-create.md",
    "session-summary.md",
    "rise-pde-session.md",
]

SKILLS_DIR = REPO_ROOT / "skills" / "coaia"


class TestCoaiaSkillsFrontmatter:
    """Validate that all bundled COAIA skills have the required frontmatter."""

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_file_exists(self, filename):
        assert (SKILLS_DIR / filename).exists(), (
            f"Expected skill file not found: skills/coaia/{filename}"
        )

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_has_name(self, filename):
        content = (SKILLS_DIR / filename).read_text(encoding="utf-8")
        assert "name:" in content, f"{filename}: missing 'name:' in frontmatter"

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_has_description(self, filename):
        content = (SKILLS_DIR / filename).read_text(encoding="utf-8")
        assert "description:" in content, f"{filename}: missing 'description:'"

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_has_version(self, filename):
        content = (SKILLS_DIR / filename).read_text(encoding="utf-8")
        assert "version:" in content, f"{filename}: missing 'version:'"

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_has_coaia_category(self, filename):
        content = (SKILLS_DIR / filename).read_text(encoding="utf-8")
        assert "category: coaia" in content, (
            f"{filename}: missing 'category: coaia' in hermes metadata"
        )

    @pytest.mark.parametrize("filename", EXPECTED_SKILLS)
    def test_skill_platforms_includes_cli(self, filename):
        content = (SKILLS_DIR / filename).read_text(encoding="utf-8")
        assert "platforms: [cli]" in content, (
            f"{filename}: missing 'platforms: [cli]'"
        )
