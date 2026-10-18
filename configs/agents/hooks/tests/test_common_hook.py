"""Regression tests using disposable Git repositories and real subprocesses."""

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest import mock

HOOK = Path(__file__).resolve().parents[1] / "common_hook.py"


class CommonHookTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(HOOK.is_file(), "common hook implementation is missing")
        spec = importlib.util.spec_from_file_location("common_hook", HOOK)
        self.core = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.core)
        adapter_spec = importlib.util.spec_from_file_location(
            "adapters", HOOK.parent / "adapters.py"
        )
        self.adapters = importlib.util.module_from_spec(adapter_spec)
        adapter_spec.loader.exec_module(self.adapters)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        self.root.mkdir()
        self.state = Path(self.temp.name) / "state"
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", "/dev/null")
        self.write("tracked.txt", "original\n")
        self.git("add", ".")
        self.git("commit", "-qm", "initial")

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.root), *args],
            check=True,
            capture_output=True,
        ).stdout.decode()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def event(self, kind, **kwargs):
        value = {
            "kind": kind,
            "harness": "test",
            "workspace": str(self.root),
            "session_id": "one",
            "turn_id": "turn-one",
            "stop_control": True,
        }
        value.update(kwargs)
        return self.core.handle_event(value, state_dir=self.state)

    def test_destructive_git_operations_and_safe_variants(self):
        cases = {
            "git reset --hard HEAD": "deny",
            "git -C . reset --hard": "deny",
            "git clean -fdx": "deny",
            "git clean -df": "deny",
            "git clean -fdn": "allow",
            "git clean --force --dry-run": "allow",
            "git push -f origin main": "deny",
            "git push --force origin main": "deny",
            "git push origin +HEAD:main": "deny",
            "git push --force-with-lease origin main": "allow",
            "git push -f --force-with-lease": "deny",
            "git status && git diff --check": "allow",
            "echo 'git reset --hard'": "allow",
            "bash -c 'git reset --hard'": "deny",
            "env LANG=C git clean -f": "deny",
        }
        for command, expected in cases.items():
            with self.subTest(command=command):
                self.assertEqual(self.event("pre", command=command)["action"], expected)

    def test_conversation_approval_cannot_disable_policy(self):
        result = self.event(
            "pre",
            command="git reset --hard",
            approved=True,
            tool_input={"approval": "user approved"},
        )
        self.assertEqual(result["action"], "deny")

    def test_reading_git_metadata_is_allowed(self):
        self.assertEqual(
            self.event("pre", tool_name="Read", paths=[".git/config"])["action"],
            "allow",
        )

    def test_tool_cwd_does_not_split_session_correction_budget(self):
        self.event("start")
        self.write("child/file.txt", "bad \n")
        self.assertEqual(
            self.event("pre", cwd=str(self.root / "child"), paths=["../.git/HEAD"])[
                "action"
            ],
            "deny",
        )
        self.assertEqual(
            self.event("stop", cwd=str(self.root / "child"))["action"], "continue"
        )
        self.assertEqual(self.event("stop")["action"], "notify")

    def test_external_gate_and_common_gate_share_one_correction(self):
        self.event("start")
        self.write("tracked.txt", "bad \n")
        self.assertEqual(self.event("stop")["action"], "continue")
        result = self.event("stop", external_issues=["Project check failed"])
        self.assertEqual(result["action"], "notify")
        self.assertIn("Project check failed", result["message"])

    def test_native_stop_reentry_never_requests_another_correction(self):
        self.event("start")
        self.write("tracked.txt", "bad \n")
        self.assertEqual(self.event("stop", stop_hook_active=True)["action"], "notify")
        self.assertEqual(self.event("stop")["action"], "notify")

    def test_concurrent_stops_claim_only_one_correction(self):
        self.event("start")
        self.write("tracked.txt", "bad \n")
        with ThreadPoolExecutor(max_workers=2) as pool:
            actions = list(pool.map(lambda _: self.event("stop")["action"], range(2)))
        self.assertEqual(sorted(actions), ["continue", "notify"])

    def test_user_policy_can_disable_one_forbidden_operation(self):
        payload = {
            "kind": "pre",
            "harness": "test",
            "workspace": str(self.root),
            "session_id": "one",
            "command": "git reset --hard",
        }
        result = self.core.handle_event(
            payload, policy={"deny": {"git_reset_hard": False}}, state_dir=self.state
        )
        self.assertEqual(result["action"], "allow")
        payload["command"] = "git clean -f"
        self.assertEqual(
            self.core.handle_event(
                payload,
                policy={"deny": {"git_reset_hard": False}},
                state_dir=self.state,
            )["action"],
            "deny",
        )

    def test_native_patch_and_shell_writes_to_git_metadata_are_denied(self):
        for extra in (
            {"paths": [".git/config"]},
            {"tool_input": {"patch": "*** Update File: .git/config\n+x"}},
            {"command": "printf x > .git/HEAD"},
            {"command": "cp saved .git/config"},
            {"command": "rm -rf .git"},
        ):
            with self.subTest(extra=extra):
                self.assertEqual(self.event("pre", **extra)["action"], "deny")

    def test_linked_worktree_metadata_is_protected(self):
        worktree = Path(self.temp.name) / "worktree"
        self.git("worktree", "add", "-qb", "other", str(worktree))
        gitdir = self.git("rev-parse", "--absolute-git-dir").strip()
        self.assertEqual(
            self.event(
                "pre", workspace=str(worktree), paths=[gitdir + "/refs/heads/main"]
            )["action"],
            "deny",
        )
        self.assertEqual(
            self.event("pre", workspace=str(worktree), paths=[".git"])["action"], "deny"
        )

    def test_existing_problem_is_ignored_but_new_whitespace_fails(self):
        self.write("tracked.txt", "existing bad  \n")
        self.event("start")
        self.write("tracked.txt", "header\nexisting bad  \nnew bad  \n")
        result = self.event("post")
        self.assertTrue(result["issues"])
        self.assertEqual(len(result["issues"]), 1)
        self.assertIn("new bad", result["issues"][0]["text"])
        first = self.event("stop")
        second = self.event("stop")
        self.assertEqual(first["action"], "continue")
        self.assertEqual(second["action"], "notify")

    def test_staged_and_untracked_conflicts_are_checked(self):
        self.event("start")
        self.write("tracked.txt", "staged bad \n")
        self.git("add", "tracked.txt")
        self.write("tracked.txt", "working copy clean\n")
        self.write(
            "new.txt", "<<<<<<< HEAD\nconflict\n=======\nother\n>>>>>>> branch\n"
        )
        result = self.event("post")
        kinds = {issue["kind"] for issue in result["issues"]}
        self.assertEqual(kinds, {"whitespace", "conflict_marker"})
        self.assertEqual(self.event("stop")["action"], "continue")

    def test_stop_catches_changes_without_post_event(self):
        self.event("start")
        self.write("tracked.txt", "unobserved bad \n")
        self.assertEqual(self.event("stop")["action"], "continue")

    def test_notification_adapter_does_not_request_correction(self):
        self.event("start")
        self.write("tracked.txt", "bad \n")
        result = self.event("stop", stop_control=False)
        self.assertEqual(result["action"], "notify")
        self.assertTrue(result["issues"])

    def test_corrected_content_is_rechecked_and_next_turn_gets_own_budget(self):
        self.event("start")
        self.write("tracked.txt", "bad \n")
        self.assertEqual(self.event("stop")["action"], "continue")
        self.write("tracked.txt", "clean\n")
        self.assertEqual(self.event("stop")["action"], "allow")
        self.write("tracked.txt", "next bad \n")
        self.assertEqual(self.event("stop", turn_id="turn-two")["action"], "continue")

    def test_missing_session_does_not_share_correction_state(self):
        self.write("tracked.txt", "bad \n")
        result = self.event("stop", session_id=None)
        self.assertEqual(result["action"], "notify")
        self.assertTrue(result["pending"])
        self.assertFalse(self.state.exists())

    def test_session_and_harness_baselines_do_not_leak(self):
        self.event("start")
        self.write("tracked.txt", "existing for second \n")
        self.event("start", session_id="two")
        self.assertEqual(self.event("stop", session_id="two")["action"], "allow")
        self.assertEqual(self.event("stop")["action"], "continue")
        self.event("start", harness="other")
        self.assertEqual(self.event("stop", harness="other")["action"], "allow")

    def test_non_git_workspace_is_safe_and_loads_real_handover(self):
        other = Path(self.temp.name) / "plain"
        other.mkdir()
        (other / "HANDOVER.md").write_text("# Actual handover\nCurrent context.\n")
        result = self.event("start", workspace=str(other))
        self.assertIn("Current context.", result["message"])
        stopped = self.event("stop", workspace=str(other))
        self.assertEqual(stopped["action"], "notify")
        self.assertIn("non-Git", stopped["message"])

    def test_broken_git_metadata_never_counts_as_successful_non_git_audit(self):
        (self.root / ".git" / "HEAD").unlink()
        started = self.event("start")
        self.assertTrue(started["pending"])
        self.assertIn("Git", started["message"])
        self.assertEqual(self.event("pre", command="git status")["action"], "deny")

    def test_clean_stop_reentry_still_consumes_shared_correction_budget(self):
        self.event("start")
        self.assertEqual(self.event("stop", stop_hook_active=True)["action"], "allow")
        self.assertEqual(
            self.event("stop", external_issues=["External check failed"])["action"],
            "notify",
        )

    def test_handover_never_generates_placeholder_and_saves_explicit_text(self):
        original = self.write("HANDOVER.md", "# Actual\nKeep this.\n")
        self.event("handover")
        self.assertEqual(original.read_text(), "# Actual\nKeep this.\n")
        self.event("handover", handover_text="# Updated\nSaved context.\n")
        self.assertEqual(original.read_text(), "# Updated\nSaved context.\n")

    def test_prompt_reminds_research_without_running_unknown_commands(self):
        self.assertIn("official source", self.event("prompt")["message"])

    def test_claude_prompt_keeps_full_reminder(self):
        message = self.event("prompt", harness="claude")["message"]
        self.assertEqual(message, self.core.REMINDER)

    def test_openclaw_reminds_only_interactive_runs(self):
        def native(name, origin, run):
            event = self.adapters.normalize(
                "openclaw",
                name,
                {
                    "sessionId": "claw-" + origin,
                    "workspaceDir": str(self.root),
                    "runId": run,
                    "origin": origin,
                },
            )
            return self.core.handle_event(event, state_dir=self.state)["message"]

        self.assertEqual(
            native("UserPromptSubmit", "interactive", "run-one"),
            self.core.OPENCLAW_REMINDER,
        )
        self.assertEqual(native("UserPromptSubmit", "cron", "run-one"), "")
        self.assertEqual(native("UserPromptSubmit", "unknown", "run-one"), "")
        self.write("HANDOVER.md", "# Actual\nCurrent context.\n")
        started = native("before_prompt_build", "heartbeat", "run-two")
        self.assertIn("Current context.", started)
        self.assertNotIn("official source", started)

    def test_identified_prompt_advances_unknown_turn_once(self):
        self.event("start", turn_id=None)
        self.write("tracked.txt", "bad \n")
        self.event("prompt", turn_id=None, prompt_event_id="prompt-one")
        self.assertEqual(self.event("stop", turn_id=None)["action"], "continue")
        self.event("prompt", turn_id=None, prompt_event_id="prompt-one")
        self.assertEqual(self.event("stop", turn_id=None)["action"], "notify")
        self.event("prompt", turn_id=None, prompt_event_id="prompt-two")
        self.assertEqual(self.event("stop", turn_id=None)["action"], "continue")

    def test_duplicate_start_and_identified_prompt_deliver_context_once(self):
        self.write("HANDOVER.md", "# Actual\nCurrent context.\n")
        self.assertIn("Current context.", self.event("start")["message"])
        self.assertEqual(self.event("start")["message"], "")
        self.assertIn(
            "official source", self.event("prompt", prompt_event_id="first")["message"]
        )
        self.assertEqual(self.event("prompt", prompt_event_id="first")["message"], "")
        self.assertIn(
            "official source",
            self.event("prompt", turn_id="next", prompt_event_id="next")["message"],
        )

    def test_copilot_native_timestamp_separates_repeated_prompts(self):
        payload = {
            "sessionId": "copilot-native",
            "cwd": str(self.root),
            "prompt": "same text",
        }

        def native(name, **fields):
            event = self.adapters.normalize("copilot", name, {**payload, **fields})
            return self.core.handle_event(event, state_dir=self.state)

        native("sessionStart", timestamp=100)
        native("userPromptSubmitted", timestamp=101)
        native("userPromptSubmitted", timestamp=101)  # global/project duplicate
        self.write("tracked.txt", "bad \n")
        self.assertEqual(
            native("agentStop", timestamp=102, stop_hook_active=False)["action"],
            "continue",
        )
        native(
            "UserPromptSubmit", timestamp="1970-01-01T00:00:00.101Z"
        )  # compatible duplicate
        self.assertEqual(
            native("agentStop", timestamp=103, stop_hook_active=True)["action"],
            "notify",
        )
        native("userPromptSubmitted", timestamp=104)
        self.assertEqual(
            native("agentStop", timestamp=105, stop_hook_active=False)["action"],
            "continue",
        )
        self.assertEqual(
            native("agentStop", timestamp=106, stop_hook_active=False)["action"],
            "notify",
        )

    def test_unknown_turn_context_dedup_does_not_invent_correction_budget(self):
        payload = {"conversationId": "agy-native", "workspacePaths": [str(self.root)]}

        def native(name):
            event = self.adapters.normalize("antigravity", name, payload)
            return self.core.handle_event(event, state_dir=self.state)

        native("SessionStart")
        self.assertIn("official source", native("PreInvocation")["message"])
        self.assertEqual(native("PreInvocation")["message"], "")
        self.write("tracked.txt", "bad \n")
        self.assertEqual(native("Stop")["action"], "notify")
        self.assertEqual(native("PreInvocation")["message"], "")
        anonymous = self.adapters.normalize(
            "antigravity", "PreInvocation", {"workspacePaths": [str(self.root)]}
        )
        self.assertIn(
            "official source",
            self.core.handle_event(anonymous, state_dir=self.state)["message"],
        )
        self.assertIn(
            "official source",
            self.core.handle_event(anonymous, state_dir=self.state)["message"],
        )

    def test_grok_receives_actual_context_once_on_pre(self):
        self.write("HANDOVER.md", "# Context\nActual handover details.\n")
        self.event("start", harness="grok")
        first = self.event("pre", harness="grok", command="git status")
        second = self.event("pre", harness="grok", command="git status")
        self.assertIn("Actual handover details.", first["message"])
        self.assertIn("official source", first["message"])
        self.assertEqual(second["message"], "")

    def test_copying_git_metadata_as_read_source_is_allowed(self):
        self.assertEqual(
            self.event("pre", command="cp .git/config /tmp/config-backup")["action"],
            "allow",
        )

    def test_cli_stdin_is_bounded_even_if_sender_never_closes_pipe(self):
        process = subprocess.Popen(
            ["python3", str(HOOK), "--harness", "claude", "--event", "PreToolUse"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        )

        def cleanup():
            if process.poll() is None:
                process.kill()
            process.wait()
            for stream in (process.stdin, process.stdout, process.stderr):
                stream.close()

        self.addCleanup(cleanup)
        process.stdin.write(b'{"cwd":')
        process.stdin.flush()
        process.wait(timeout=5)
        output = process.stdout.read().decode()
        self.assertIn("deny", output)
        self.assertIn("timeout", output.lower())
        process.stdin.close()
        process.stdout.close()
        process.stderr.close()

    def test_auto_harness_malformed_pre_input_fails_closed(self):
        process = subprocess.run(
            ["python3", str(HOOK), "--harness", "auto", "--event", "PreToolUse"],
            check=False,
            input="{bad json",
            text=True,
            capture_output=True,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
            timeout=5,
        )
        self.assertEqual(process.returncode, 2)
        self.assertIn("Malformed hook input", process.stderr)
        self.assertNotIn("Traceback", process.stderr)

    def test_auto_harness_malformed_post_input_reports_without_reprompt(self):
        process = subprocess.run(
            ["python3", str(HOOK), "--harness", "auto", "--event", "PostToolUse"],
            check=False,
            input="{bad json",
            text=True,
            capture_output=True,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
            timeout=5,
        )
        self.assertEqual(process.returncode, 0)
        self.assertIn("Malformed hook input", process.stderr)
        self.assertNotIn("Traceback", process.stderr)

    def test_json_policy_path_and_invalid_policy_are_validated(self):
        path = Path(self.temp.name) / "policy.json"
        path.write_text(json.dumps({"deny": {"git_reset_hard": False}}))
        self.assertFalse(self.core.load_policy(path)["deny"]["git_reset_hard"])
        path.write_text('{"deny":{"git_reset_hard":"false"}}')
        with self.assertRaises(self.core.HookError):
            self.core.load_policy(path)
        with self.assertRaises(self.core.HookError):
            self.core.load_policy(Path(self.temp.name) / "missing.json")

    def test_explicit_check_cannot_stage_or_autofix(self):
        payload = {
            "kind": "stop",
            "workspace": str(self.root),
            "harness": "test",
            "session_id": "one",
            "turn_id": "turn-one",
            "stop_control": True,
        }
        for argv in (
            ["git", "add", "."],
            ["git", "commit", "-am", "no"],
            ["ruff", "check", "--fix"],
        ):
            with self.subTest(argv=argv):
                result = self.core.handle_event(
                    payload, {"project_commands": [{"argv": argv}]}, self.state
                )
                self.assertTrue(result["pending"])
                self.assertIn("check", result["message"].lower())

    def test_default_state_directory_is_not_created_for_unknown_identity(self):
        result = self.event("post", session_id="")
        self.assertEqual(result["action"], "notify")
        self.assertTrue(result["pending"])
        self.assertFalse(self.state.exists())

    def test_unknown_project_commands_are_not_discovered_or_run(self):
        sentinel = self.root / "executed"
        self.write("Makefile", "check:\n\ttouch executed\n")
        self.write("package.json", json.dumps({"scripts": {"test": "touch executed"}}))
        self.event("start")
        self.write("tracked.txt", "changed\n")
        self.event("stop")
        self.assertFalse(sentinel.exists())

    def test_read_only_git_inspection_does_not_execute_clean_filters(self):
        self.event("start")
        marker = Path(self.temp.name) / "filter-executed"
        self.write(".gitattributes", "tracked.txt filter=unexpected\n")
        self.git("config", "filter.unexpected.clean", "touch " + str(marker) + "; cat")
        self.write("tracked.txt", "changed\n")
        self.event("stop")
        self.assertFalse(
            marker.exists(), "Git inspection executed an unconfigured repository filter"
        )

    def test_loaded_global_policy_cannot_execute_project_commands(self):
        marker = Path(self.temp.name) / "global-check-ran"
        script = Path(self.temp.name) / "check.py"
        script.write_text(
            "from pathlib import Path\nPath(" + repr(str(marker)) + ").touch()\n"
        )
        project_policy = {"project_commands": [{"argv": ["python3", str(script)]}]}
        path = Path(self.temp.name) / "global-policy.json"
        path.write_text(json.dumps(project_policy))
        with self.assertRaisesRegex(self.core.HookError, "project_commands"):
            self.core.load_policy(path)
        self.write("tracked.txt", "changed\n")
        with mock.patch.dict(os.environ, {"AGENT_HOOK_POLICY": str(path)}):
            stopped = self.event("stop")
            self.assertEqual(stopped["action"], "notify")
            self.assertTrue(stopped["pending"])
            self.assertIn("project_commands", stopped["message"])
            self.assertFalse(marker.exists())
            # A reviewed local wrapper may still supply its own explicit argv.
            event = {
                "kind": "stop",
                "workspace": str(self.root),
                "session_id": "local-check",
                "harness": "test",
                "stop_control": True,
            }
            local = self.core.handle_event(
                event, policy=project_policy, state_dir=self.state
            )
            self.assertEqual(local["action"], "allow")
            self.assertTrue(marker.exists())

    def test_explicit_project_check_runs_once_per_content_fingerprint(self):
        self.event("start")
        self.write("tracked.txt", "changed\n")
        script = self.write(
            "check.py",
            "from pathlib import Path\np=Path('runs')\n"
            "p.write_text(p.read_text()+'x' if p.exists() else 'x')\n",
        )
        self.write(".gitignore", "runs\n")
        payload = {
            "kind": "stop",
            "workspace": str(self.root),
            "harness": "test",
            "session_id": "one",
            "turn_id": "turn-one",
            "stop_control": True,
        }
        policy = {
            "project_commands": [{"argv": ["python3", str(script)], "timeout": 2}]
        }
        self.assertEqual(
            self.core.handle_event(payload, policy, self.state)["action"], "allow"
        )
        self.assertEqual(
            self.core.handle_event(payload, policy, self.state)["action"], "allow"
        )
        self.assertEqual((self.root / "runs").read_text(), "x")
        self.write("tracked.txt", "changed again\n")
        self.core.handle_event(payload, policy, self.state)
        self.assertEqual((self.root / "runs").read_text(), "xx")

    def test_project_check_editing_files_keeps_audit_pending(self):
        self.event("start")
        script = self.write(
            "check.py",
            "from pathlib import Path\nPath('tracked.txt').write_text('new bad \\n')\n",
        )
        payload = {
            "kind": "stop",
            "workspace": str(self.root),
            "harness": "test",
            "session_id": "one",
            "turn_id": "turn-one",
            "stop_control": True,
        }
        result = self.core.handle_event(
            payload,
            {"project_commands": [{"argv": ["python3", str(script)]}]},
            self.state,
        )
        self.assertTrue(result["pending"])
        self.assertEqual(result["action"], "continue")

    def test_project_check_timeout_is_reported_without_hanging(self):
        self.event("start")
        script = self.write("check.py", "import time\ntime.sleep(30)\n")
        payload = {
            "kind": "stop",
            "workspace": str(self.root),
            "harness": "test",
            "session_id": "one",
            "turn_id": "turn-one",
            "stop_control": True,
        }
        result = self.core.handle_event(
            payload,
            {"project_commands": [{"argv": ["python3", str(script)], "timeout": 0.1}]},
            self.state,
        )
        self.assertEqual(result["action"], "continue")
        self.assertIn("timeout", result["message"].lower())


if __name__ == "__main__":
    unittest.main()
