"""Release-contract fixtures, not evidence of live native firing."""

import sys
import unittest
from pathlib import Path
from unittest import mock

HOOKS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS))


class AdapterContracts(unittest.TestCase):
    def setUp(self):
        self.assertTrue(
            (HOOKS / "adapters.py").is_file(),
            "native adapter implementation is missing",
        )
        import adapters

        self.a = adapters

    def test_native_tool_payloads_keep_workspace_session_and_input(self):
        fixtures = {
            "claude": {
                "session_id": "s",
                "cwd": "/tmp/project",
                "tool_name": "Bash",
                "tool_input": {"command": "git status"},
            },
            "codex": {
                "session_id": "s",
                "cwd": "/tmp/project",
                "turn_id": "t",
                "tool_name": "exec_command",
                "tool_input": {"cmd": "git status"},
            },
            "grok": {
                "sessionId": "s",
                "cwd": "/tmp/project",
                "promptId": "t",
                "toolName": "run_terminal_command",
                "toolInput": {"command": "git status"},
            },
            "antigravity": {
                "conversationId": "s",
                "workspacePaths": ["/tmp/project"],
                "toolCall": {
                    "name": "run_command",
                    "args": {"CommandLine": "git status", "Cwd": "/tmp/project"},
                },
            },
            "kiro": {
                "session_id": "s",
                "cwd": "/tmp/project",
                "tool_name": "execute_bash",
                "tool_input": {"command": "git status"},
            },
            "copilot": {
                "sessionId": "s",
                "cwd": "/tmp/project",
                "toolName": "bash",
                "toolArgs": '{"command":"git status"}',
            },
            "opencode": {
                "sessionID": "s",
                "cwd": "/tmp/project",
                "messageID": "t",
                "tool": "bash",
                "input": {"command": "git status"},
            },
            "openclaw": {
                "sessionId": "s",
                "workspaceDir": "/tmp/project",
                "runId": "t",
                "toolName": "exec",
                "params": {"command": "git status"},
            },
        }
        for harness, payload in fixtures.items():
            with self.subTest(harness=harness):
                event = self.a.normalize(harness, "PreToolUse", payload)
                self.assertEqual(event["kind"], "pre")
                self.assertEqual(event["workspace"], "/tmp/project")
                self.assertEqual(event["session_id"], "s")
                self.assertEqual(event["command"], "git status")
                self.assertIsInstance(event["tool_input"], dict)

    def test_copilot_pascal_payload(self):
        event = self.a.normalize(
            "copilot",
            "PreToolUse",
            {
                "session_id": "s",
                "cwd": "/tmp/p",
                "tool_name": "Write",
                "tool_input": {"file_path": "doc.md"},
            },
        )
        self.assertEqual(event["paths"], ["doc.md"])
        self.assertEqual(event["tool_name"], "Write")

    def test_codex_raw_patch_is_not_misparsed_as_json(self):
        patch = "*** Begin Patch\n*** Add File: doc.md\n+content\n*** End Patch"
        event = self.a.normalize(
            "codex",
            "PreToolUse",
            {"cwd": "/tmp/p", "tool_name": "apply_patch", "tool_input": patch},
        )
        self.assertEqual(event["patch"], patch)
        self.assertEqual(event["paths"], ["doc.md"])

    def test_patch_move_and_nested_edit_paths_preserved(self):
        patch = "*** Update File: a.md\n*** Move to: b.md\n"
        event = self.a.normalize(
            "claude",
            "PreToolUse",
            {
                "tool_name": "apply_patch",
                "tool_input": {"patch": patch, "edits": [{"file_path": "c.md"}]},
            },
        )
        self.assertCountEqual(event["paths"], ["a.md", "b.md", "c.md"])

    def test_argv_command_and_execution_directory_preserved(self):
        event = self.a.normalize(
            "codex",
            "PreToolUse",
            {
                "cwd": "/tmp/project",
                "tool_name": "shell",
                "tool_input": {
                    "command": ["git", "commit", "-m", "two words"],
                    "workdir": "/tmp/other",
                },
            },
        )
        self.assertEqual(event["workspace"], "/tmp/project")
        self.assertEqual(event["cwd"], "/tmp/other")
        self.assertEqual(event["command"], "git commit -m 'two words'")

    def test_unknown_session_and_turn_stay_unknown(self):
        event = self.a.normalize("claude", "Stop", {"cwd": "/tmp/p"})
        self.assertIsNone(event["session_id"])
        self.assertIsNone(event["turn_id"])

    def test_relative_tool_directory_resolves_from_session_workspace(self):
        event = self.a.normalize(
            "codex",
            "PreToolUse",
            {
                "cwd": "/tmp/project",
                "tool_name": "exec_command",
                "tool_input": {"cmd": "git status", "workdir": "child"},
            },
        )
        self.assertEqual(event["workspace"], "/tmp/project")
        self.assertEqual(event["cwd"], "/tmp/project/child")

    def test_auto_payload_routes_native_grok_and_copilot(self):
        grok = {
            "sessionId": "s",
            "workspaceRoot": "/tmp/p",
            "hookEventName": "pre_tool_use",
            "toolName": "run_terminal_command",
            "toolInput": {"command": "git status"},
        }
        copilot = {
            "sessionId": "s",
            "timestamp": 1,
            "cwd": "/tmp/p",
            "toolName": "bash",
            "toolArgs": {"command": "git status"},
        }
        self.assertEqual(
            self.a.normalize("auto", "PreToolUse", grok)["harness"], "grok"
        )
        self.assertEqual(
            self.a.normalize("auto", "PreToolUse", copilot)["harness"], "copilot"
        )

    def test_auto_snake_compatibility_uses_ancestor_only_for_auto(self):
        payload = {
            "session_id": "s",
            "cwd": "/tmp/p",
            "tool_name": "Bash",
            "tool_input": {"command": "git status"},
        }
        with mock.patch.object(self.a, "ancestor_harness", return_value="copilot"):
            self.assertEqual(
                self.a.normalize("auto", "PreToolUse", payload)["harness"], "copilot"
            )
            self.assertEqual(
                self.a.normalize("claude", "PreToolUse", payload)["harness"], "claude"
            )

    def test_auto_ancestor_failure_defaults_without_inventing_harness(self):
        with mock.patch.object(self.a, "ancestor_harness", return_value=None):
            self.assertEqual(
                self.a.normalize("auto", "Stop", {"session_id": "s"})["harness"],
                "claude",
            )

    def test_ancestor_classification_only_matches_program_or_script(self):
        self.assertEqual(
            self.a.command_harness(
                ["/usr/bin/node", "/store/github-copilot-cli/index.js", "-p", "secret"]
            ),
            "copilot",
        )
        self.assertEqual(
            self.a.command_harness(["/store/bin/copilot-runtime", "--stdio"]), "copilot"
        )
        self.assertIsNone(self.a.command_harness(["/bin/bash", "-c", "copilot prompt"]))
        self.assertIsNone(
            self.a.command_harness(["/usr/bin/python3", "notes/copilot.txt"])
        )

    def test_transcript_and_prompt_identity_forwarded_for_unknown_turns(self):
        event = self.a.normalize(
            "claude",
            "UserPromptSubmit",
            {
                "transcript_path": "/tmp/transcript",
                "prompt": "user text",
                "prompt_event_id": "native-admission",
            },
        )
        self.assertEqual(event["transcript_path"], "/tmp/transcript")
        self.assertEqual(event["prompt"], "user text")
        self.assertEqual(event["prompt_event_id"], "native-admission")

    def test_copilot_prompt_timestamp_is_stable_across_native_envelopes(self):
        native = self.a.normalize(
            "copilot",
            "userPromptSubmitted",
            {
                "sessionId": "s",
                "timestamp": 1791853200123,
                "cwd": "/tmp/p",
                "prompt": "same",
            },
        )
        compatible = self.a.normalize(
            "copilot",
            "UserPromptSubmit",
            {
                "session_id": "s",
                "timestamp": "2026-10-13T01:00:00.123Z",
                "cwd": "/tmp/p",
                "prompt": "same",
            },
        )
        self.assertEqual(native["prompt_event_id"], compatible["prompt_event_id"])
        stopped = self.a.normalize(
            "copilot",
            "agentStop",
            {
                "sessionId": "s",
                "timestamp": 1791853200456,
                "cwd": "/tmp/p",
                "stop_hook_active": True,
            },
        )
        self.assertNotIn("prompt_event_id", stopped)
        self.assertIsNone(stopped["turn_id"])

    def test_observer_stop_cannot_request_correction(self):
        for harness in ("opencode", "openclaw", "antigravity", "kiro"):
            with self.subTest(harness=harness):
                event = self.a.normalize(harness, "Stop", {})
                self.assertFalse(event["stop_control"])
                output, code = self.a.emit(
                    harness, "Stop", {"action": "continue", "message": "fix"}
                )
                self.assertEqual(code, 0)
                self.assertNotEqual(
                    (output or {}).get("decision")
                    if isinstance(output, dict)
                    else None,
                    "block",
                )

    def test_native_stop_reentry_is_preserved(self):
        for harness, flag in (
            ("claude", "stop_hook_active"),
            ("codex", "stop_hook_active"),
            ("grok", "stopHookActive"),
            ("copilot", "stop_hook_active"),
        ):
            with self.subTest(harness=harness):
                event = self.a.normalize(harness, "Stop", {flag: True})
                self.assertTrue(event["stop_hook_active"])
                self.assertTrue(event["stop_control"])

    def test_pre_denials_use_native_protocols(self):
        result = {"action": "deny", "message": "denied"}
        for harness in ("claude", "codex", "grok"):
            output, code = self.a.emit(harness, "PreToolUse", result)
            self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
            self.assertEqual(code, 0)
        self.assertEqual(
            self.a.emit("copilot", "preToolUse", result),
            ({"permissionDecision": "deny", "permissionDecisionReason": "denied"}, 0),
        )
        self.assertEqual(self.a.emit("kiro", "preToolUse", result), ("denied", 2))
        self.assertEqual(
            self.a.emit("antigravity", "PreToolUse", result),
            ({"decision": "deny", "reason": "denied"}, 0),
        )
        self.assertEqual(
            self.a.emit("openclaw", "before_tool_call", result)[0]["block"], True
        )

    def test_native_context_is_delivered_only_where_consumed(self):
        result = {"action": "allow", "message": "research"}
        for harness in ("claude", "codex", "grok"):
            output, code = self.a.emit(harness, "PreToolUse", result)
            self.assertEqual(code, 0)
            self.assertEqual(
                output["hookSpecificOutput"]["additionalContext"], "research"
            )
        self.assertEqual(
            self.a.emit("copilot", "postToolUse", result),
            ({"additionalContext": "research"}, 0),
        )
        self.assertEqual(self.a.emit("kiro", "agentSpawn", result), ("research", 0))
        self.assertEqual(
            self.a.emit("antigravity", "PreInvocation", result),
            ({"injectSteps": [{"ephemeralMessage": "research"}]}, 0),
        )
        self.assertEqual(self.a.emit("antigravity", "PostToolUse", result), ({}, 0))
        self.assertEqual(self.a.emit("grok", "SessionStart", result), ({}, 0))

    def test_native_stop_continue_only_on_supported_harness(self):
        for harness in ("claude", "codex", "grok", "copilot"):
            with self.subTest(harness=harness):
                self.assertEqual(
                    self.a.emit(
                        harness, "Stop", {"action": "continue", "message": "fix"}
                    ),
                    ({"decision": "block", "reason": "fix"}, 0),
                )

    def test_event_aliases_and_handover_text(self):
        for event, kind in (
            ("agentSpawn", "start"),
            ("before_tool_call", "pre"),
            ("execute.after", "post"),
            ("agent_end", "stop"),
            ("PreCompact", "handover"),
            ("UserPromptSubmit", "prompt"),
        ):
            self.assertEqual(
                self.a.normalize("claude", event, {"handover_text": "saved"})["kind"],
                kind,
            )
        self.assertEqual(
            self.a.normalize("claude", "PreCompact", {"handover_text": "saved"})[
                "handover_text"
            ],
            "saved",
        )

    def test_antigravity_continuation_only_for_natural_idle_stop(self):
        for reason, idle, enabled in (
            ("model_stop", True, True),
            ("NO_TOOL_CALL", True, True),
            ("model_stop", False, False),
            ("max_steps_exceeded", True, False),
            ("error", True, False),
            (None, True, False),
        ):
            event = self.a.normalize(
                "antigravity", "Stop", {"terminationReason": reason, "fullyIdle": idle}
            )
            self.assertEqual(event["stop_control"], enabled)
            self.assertEqual(
                event["stop_reason"],
                "natural"
                if enabled
                else "unknown"
                if reason in (None, "model_stop")
                else "error"
                if reason == "error"
                else "abort",
            )
        self.assertEqual(
            self.a.emit(
                "antigravity",
                "Stop",
                {"action": "continue", "message": "next", "loop": {"state": "running"}},
            ),
            ({"decision": "continue", "reason": "next"}, 0),
        )
        self.assertEqual(
            self.a.emit(
                "antigravity", "Stop", {"action": "continue", "message": "next"}
            ),
            ({}, 0),
        )

    def test_bridge_metadata_and_lifecycle_classification(self):
        opencode = self.a.normalize(
            "opencode",
            "session.execution.succeeded",
            {
                "sessionID": "s",
                "stop_reason": "natural",
                "request_id": "r",
                "loop_id": "l",
                "owner_epoch": 2,
            },
        )
        self.assertEqual(opencode["kind"], "stop")
        self.assertTrue(opencode["stop_control"])
        self.assertEqual(opencode["owner_epoch"], 2)
        self.assertEqual(opencode["request_id"], "r")
        self.assertFalse(
            self.a.normalize("opencode", "session.idle", {})["stop_control"]
        )
        finalize = self.a.normalize(
            "openclaw", "before_agent_finalize", {"origin": "interactive"}
        )
        self.assertTrue(finalize["stop_control"])
        self.assertFalse(
            self.a.normalize("openclaw", "before_agent_finalize", {"origin": "cron"})[
                "stop_control"
            ]
        )
        self.assertTrue(
            self.a.normalize("openclaw", "agent_end", {})["observation_only"]
        )
        interrupted = self.a.normalize("codex", "Interrupt", {})
        self.assertEqual(interrupted["kind"], "end")
        self.assertEqual(interrupted["stop_reason"], "abort")

    def test_bridge_private_results_keep_durable_request(self):
        value = {
            "action": "continue",
            "message": "next",
            "loop": {"id": "l", "request_id": "r", "state": "running"},
        }
        self.assertEqual(
            self.a.emit("opencode", "session.execution.succeeded", value)[0]["loop"],
            value["loop"],
        )
        self.assertEqual(
            self.a.emit("opencode", "session.execution.succeeded", value)[0]["action"],
            "continue",
        )
        self.assertEqual(
            self.a.emit("openclaw", "before_agent_finalize", value)[0]["action"],
            "revise",
        )
        self.assertNotIn("action", self.a.emit("openclaw", "agent_end", value)[0])

    def test_bad_payload_rejected(self):
        for value in ([], None, "text"):
            with self.assertRaises(ValueError):
                self.a.normalize("claude", "PreToolUse", value)
        with self.assertRaises(ValueError):
            self.a.normalize("claude", "PreToolUse", {"tool_input": "not json"})
        with self.assertRaises(ValueError):
            self.a.normalize("claude", "PreToolUse", {"tool_input": []})
        with self.assertRaises(ValueError):
            self.a.normalize("claude", "UnknownEvent", {})


if __name__ == "__main__":
    unittest.main()
