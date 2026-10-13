"""Wiring regressions: preservation, relocation and malformed-input safety."""

import copy
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import tomllib

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location(
    "common_wiring", ROOT / "agents/hooks/wiring.py"
)
wiring = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wiring)


def hook(event, harness="claude", home="$HOME"):
    return {
        "hooks": [
            {
                "type": "command",
                "command": f'python3 "{home}/.agents/hooks/common_hook.py" --harness {harness} --event {event}',
                "timeout": 30,
            }
        ]
    }


class WiringTests(unittest.TestCase):
    def test_json_preserves_settings_control_plane_and_disable(self):
        desired = {"hooks": {"SessionStart": [hook("SessionStart")]}}
        control = {"hooks": [{"type": "command", "command": "happier-session-control"}]}
        current = {
            "model": "custom",
            "disableAllHooks": True,
            "env": {"AUTH": "private"},
            "hooks": {"SessionStart": [control], "OtherEvent": [{"command": "other"}]},
        }
        result = wiring.merge_json(current, desired)
        self.assertEqual(result["hooks"]["SessionStart"][0], control)
        self.assertEqual(result["model"], "custom")
        self.assertEqual(result["env"], current["env"])
        self.assertTrue(result["disableAllHooks"])
        self.assertEqual(result["hooks"]["OtherEvent"], current["hooks"]["OtherEvent"])
        self.assertEqual(wiring.merge_json(result, desired), result)

    def test_legacy_replacement_preserves_sibling_hooks(self):
        current = {
            "Stop": [
                {
                    "matcher": "*",
                    "hooks": [
                        {"command": "bash ~/.agents/hooks/generate-handover.sh"},
                        {"command": "custom-check"},
                    ],
                }
            ]
        }
        desired = {"Stop": [hook("Stop")]}
        result = wiring.merge_hooks(current, desired)
        self.assertEqual(result["Stop"][0]["hooks"], [{"command": "custom-check"}])
        self.assertEqual(len(result["Stop"]), 2)
        self.assertEqual(wiring.merge_hooks(result, desired), result)

    def test_relocation_removes_previous_managed_path(self):
        current = {"PreToolUse": [hook("PreToolUse", home="/Users/old home")]}
        result = wiring.merge_hooks(current, {"PreToolUse": [hook("PreToolUse")]})
        self.assertEqual(result["PreToolUse"], [hook("PreToolUse")])

    def test_same_filename_in_project_is_unrelated(self):
        current = {"Stop": [{"command": "bash /repo/hooks/generate-handover.sh"}]}
        result = wiring.merge_hooks(current, {"Stop": [hook("Stop")]})
        self.assertEqual(result["Stop"][0], current["Stop"][0])

    def test_deliberate_disabled_handler_is_preserved(self):
        item = hook("Stop")
        item["hooks"][0]["enabled"] = False
        current = {"Stop": [item]}
        self.assertEqual(wiring.merge_hooks(current, {"Stop": [hook("Stop")]}), current)

    def test_deliberate_disabled_group_is_preserved(self):
        item = dict(hook("Stop"), enabled=False)
        current = {"Stop": [item]}
        self.assertEqual(wiring.merge_hooks(current, {"Stop": [hook("Stop")]}), current)

    def test_unrelated_declarative_hooks_not_duplicated(self):
        plugin = {"hooks": [{"command": "plugin-sync", "timeout": 10}]}
        current = {"SessionStart": [plugin]}
        desired = {"SessionStart": [copy.deepcopy(plugin), hook("SessionStart")]}
        result = wiring.merge_hooks(current, desired)
        self.assertEqual(len(result["SessionStart"]), 2)
        self.assertEqual(wiring.merge_hooks(result, desired), result)

    def test_unrelated_disabled_declarative_hook_not_enabled(self):
        existing = {"hooks": [{"command": "plugin-sync", "enabled": False}]}
        desired = {
            "SessionStart": [
                {"hooks": [{"command": "plugin-sync"}]},
                hook("SessionStart"),
            ]
        }
        result = wiring.merge_hooks({"SessionStart": [existing]}, desired)
        self.assertEqual(result["SessionStart"][0], existing)
        self.assertEqual(len(result["SessionStart"]), 2)

    def test_antigravity_named_definition_preserves_disable_trust_other(self):
        template = json.loads((ROOT / "antigravity/hooks.json").read_text())
        current = {
            "common-agents": {"enabled": False},
            "my-linter": {"enabled": True, "PostToolUse": [{"command": "custom"}]},
            "trustedWorkspaces": ["/existing"],
        }
        result = wiring.merge_json(current, template, "antigravity")
        self.assertFalse(result["common-agents"]["enabled"])
        self.assertEqual(result["my-linter"], current["my-linter"])
        self.assertEqual(result["trustedWorkspaces"], ["/existing"])
        self.assertEqual(wiring.merge_json(result, template, "antigravity"), result)

    def test_toml_preserves_hook_and_project_trust(self):
        current = {
            "hooks": {
                "state": {
                    "trusted_hooks": ["hash-old"],
                    "disabled_hooks": ["hash-disabled"],
                },
                "PreToolUse": [{"hooks": [{"command": "control-plane"}]}],
            },
            "projects": {"/project with spaces": {"trust_level": "untrusted"}},
            "auth": {"provider": "custom"},
            "model": "old",
        }
        desired = {
            "model": "declared",
            "hooks": {"PreToolUse": [hook("PreToolUse", "codex")]},
        }
        result = wiring.merge_toml(current, desired)
        self.assertEqual(result["hooks"]["state"], current["hooks"]["state"])
        self.assertEqual(result["projects"], current["projects"])
        self.assertEqual(result["auth"], current["auth"])
        self.assertEqual(result["model"], "declared")
        self.assertEqual(
            result["hooks"]["PreToolUse"][0], current["hooks"]["PreToolUse"][0]
        )
        self.assertEqual(tomllib.loads(wiring.dump_toml(result)), result)
        self.assertEqual(wiring.merge_toml(result, desired), result)

    def test_toml_text_keeps_comments_order_and_native_table_spelling(self):
        desired = '# comment kept\nmodel = "chosen" # inline comment\n\n[features]\n# feature explanation\nhooks = true\n'
        current = (
            desired
            + '\n[hooks.state]\n# machine only\ntrusted_hooks = ["existing"]\n\n[projects."/private path"]\ntrust_level = "untrusted"\n'
        )
        result = wiring.merge_toml_text(current, desired)
        self.assertTrue(result.startswith(desired))
        self.assertIn("# machine only", result)
        self.assertIn("[hooks.state]", result)
        self.assertEqual(wiring.merge_toml_text(result, desired), result)

    def test_old_deployed_codex_save_does_not_overwrite_unapplied_migration(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            live = directory / "old-live.toml"
            destination = directory / "new-source.toml"
            live.write_text('# codex cli configuration\nmodel = "old"\n')
            expected = (ROOT / "codex/config.toml").read_text()
            destination.write_text(expected)
            script = (
                (ROOT / "codex/hooks/save-config.sh")
                .read_text()
                .split("<<'PYEOF'\n", 1)[1]
                .split("\nPYEOF", 1)[0]
            )
            run = subprocess.run(
                [sys.executable, "-", str(live), str(destination)],
                check=False,
                input=script,
                text=True,
                capture_output=True,
            )
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertEqual(destination.read_text(), expected)

    def test_existing_save_scripts_keep_public_comments_and_hide_private_state(self):
        for harness in ("codex", "grok"):
            with (
                self.subTest(harness=harness),
                tempfile.TemporaryDirectory() as directory,
            ):
                directory = Path(directory)
                base = (ROOT / harness / "config.toml").read_text()
                local_text = 'private_api_token = "SECRET-DO-NOT-EXPORT"\n'
                machine = (
                    '\n[hooks.state]\ntrusted_hooks = ["MACHINE-TRUST"]\n[projects."/private"]\ntrust_level = "untrusted"\n'
                    if harness == "codex"
                    else '\n[plugins]\nprivate = "MACHINE-TRUST"\n[privacy]\nprivate = true\n'
                )
                live = directory / "live.toml"
                destination = directory / "repo.toml"
                local = directory / "config.local.toml"
                local.write_text(local_text)
                live.write_text(
                    wiring.merge_toml_text(
                        local_text + base + machine, local_text + base
                    )
                )
                destination.write_text(base)
                script = (
                    (ROOT / harness / "hooks/save-config.sh")
                    .read_text()
                    .split("<<'PYEOF'\n", 1)[1]
                    .split("\nPYEOF", 1)[0]
                )
                run = subprocess.run(
                    [sys.executable, "-", str(live), str(destination), str(local)],
                    check=False,
                    input=script,
                    text=True,
                    capture_output=True,
                )
                self.assertEqual(run.returncode, 0, run.stderr)
                saved = destination.read_text()
                self.assertNotIn("SECRET-DO-NOT-EXPORT", saved)
                self.assertNotIn("MACHINE-TRUST", saved)
                self.assertEqual(saved, base)

    def test_all_toml_templates_parse_and_merge_idempotently(self):
        for harness in ("codex", "grok"):
            with self.subTest(harness=harness):
                desired = tomllib.loads((ROOT / harness / "config.toml").read_text())
                result = wiring.merge_toml({}, desired)
                self.assertEqual(wiring.merge_toml(result, desired), result)
                self.assertEqual(tomllib.loads(wiring.dump_toml(result)), result)

    def test_toml_serializer_preserves_complex_values(self):
        original = tomllib.loads(
            'name="日本語"\nlist=[{key="one", flag=true}, {key="two", n=1}]\n["projects"."a.b"]\n"quoted key"="hello\\nthere"\n'
        )
        self.assertEqual(tomllib.loads(wiring.dump_toml(original)), original)

    def test_malformed_configuration_rejected_before_any_write(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            first = home / ".gemini/config/hooks.json"
            first.parent.mkdir(parents=True)
            first.write_text('{"my-linter": {}}')
            second = home / ".copilot/hooks/common-agents.json"
            second.parent.mkdir(parents=True)
            second.write_text("not JSON")
            with (
                patch.dict(os.environ, {"COPILOT_HOME": str(home / ".copilot")}),
                self.assertRaises(ValueError),
            ):
                wiring.install_global(home, home / ".config", ROOT)
            self.assertEqual(first.read_text(), '{"my-linter": {}}')
            self.assertEqual(second.read_text(), "not JSON")

    def test_malformed_command_rejected(self):
        with self.assertRaisesRegex(ValueError, "Malformed"):
            wiring.merge_hooks(
                {"Stop": [{"command": 'bash "unterminated'}]}, {"Stop": [hook("Stop")]}
            )

    def test_global_installer_preserves_kiro_profile_and_default_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            profile = home / ".kiro/agents/custom.json"
            profile.parent.mkdir(parents=True)
            original = {
                "name": "custom",
                "model": "mine",
                "prompt": "mine",
                "allowedTools": ["read"],
                "hooks": {"preToolUse": [{"command": "private-check"}]},
            }
            profile.write_text(json.dumps(original))
            selected = home / ".kiro/settings/cli.json"
            selected.parent.mkdir(parents=True)
            selected.write_text('{"chat.defaultAgent":"custom"}')
            with patch.dict(os.environ, {"COPILOT_HOME": str(home / ".copilot")}):
                wiring.install_global(home, home / ".config", ROOT)
                first = profile.read_text()
                wiring.install_global(home, home / ".config", ROOT)
            result = json.loads(first)
            for key in ("name", "model", "prompt", "allowedTools"):
                self.assertEqual(result[key], original[key])
            self.assertEqual(
                result["hooks"]["preToolUse"][0], {"command": "private-check"}
            )
            self.assertEqual(profile.read_text(), first)
            self.assertEqual(selected.read_text(), '{"chat.defaultAgent":"custom"}')
            self.assertFalse((profile.parent / "kiro_default.json").exists())

    def test_atomic_replacement_does_not_write_symlink_target(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "store"
            target.write_text("immutable")
            destination = Path(directory) / "config"
            destination.symlink_to(target)
            wiring.atomic_write(destination, "new mutable config")
            self.assertEqual(target.read_text(), "immutable")
            self.assertFalse(destination.is_symlink())
            self.assertEqual(destination.read_text(), "new mutable config")

    def test_claude_grok_common_handlers_are_identical_for_native_dedup(self):
        claude = json.loads((ROOT / "claude/settings.json").read_text())["hooks"]
        grok = tomllib.loads((ROOT / "grok/config.toml").read_text())["hooks"]
        for event in (
            "SessionStart",
            "UserPromptSubmit",
            "PreToolUse",
            "PostToolUse",
            "Stop",
            "PreCompact",
        ):
            with self.subTest(event=event):
                claude_owned = [
                    group
                    for group in claude[event]
                    if any(wiring.managed(item) for item in group["hooks"])
                ]
                grok_owned = [
                    group
                    for group in grok[event]
                    if any(wiring.managed(item) for item in group["hooks"])
                ]
                self.assertEqual(claude_owned, grok_owned)
                self.assertEqual(len(claude_owned), 1)

    def test_all_original_unrelated_native_handlers_are_preserved(self):
        fixtures = json.loads(
            (
                Path(__file__).parent / "fixtures/original-unrelated-hooks.json"
            ).read_text()
        )
        for harness, events in fixtures.items():
            path = (
                ROOT
                / harness
                / ("settings.json" if harness == "claude" else "config.toml")
            )
            document = (
                json.loads(path.read_text())
                if harness == "claude"
                else tomllib.loads(path.read_text())
            )
            for event, original in events.items():
                with self.subTest(harness=harness, event=event):
                    current = [
                        handler
                        for group in document["hooks"].get(event, [])
                        for handler in group.get("hooks", [])
                        if not wiring.managed(handler)
                    ]
                    self.assertEqual(current, original)

    def test_goose_pretool_runtime_failures_are_explicitly_blocking(self):
        document = json.loads((ROOT / "goose/plugin/hooks/hooks.json").read_text())
        self.assertEqual(
            document["hooks"]["PreToolUse"][0]["hooks"][0]["on_failure"], "block"
        )
        self.assertNotIn("on_failure", document["hooks"]["Stop"][0]["hooks"][0])

    def test_native_events_and_timeouts(self):
        for harness, path in (
            ("claude", "claude/settings.json"),
            ("goose", "goose/plugin/hooks/hooks.json"),
            ("copilot", "copilot/hooks/common-agents.json"),
        ):
            document = json.loads((ROOT / path).read_text())
            commands = []
            for groups in document["hooks"].values():
                for entry in groups:
                    commands.extend(entry.get("hooks", [entry]))
            owned = [entry for entry in commands if wiring.managed(entry)]
            self.assertTrue(owned)
            for entry in owned:
                self.assertIn(
                    f"--harness {'auto' if harness in ('claude', 'copilot') else harness}",
                    entry.get("command", entry.get("bash", "")),
                )
                self.assertGreaterEqual(
                    entry.get("timeout", entry.get("timeoutSec", 0)), 30
                )


if __name__ == "__main__":
    unittest.main()
