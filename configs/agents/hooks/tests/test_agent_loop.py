import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

HOOKS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS))
import agent_loop as loop


class LoopTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "repo"
        self.root.mkdir()
        self.state = Path(self.tmp.name) / "state"
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        self.file = self.root / "code.txt"
        self.file.write_text("initial\n")
        self.event = {
            "workspace": str(self.root),
            "harness": "test",
            "session_id": "s1",
            "kind": "stop",
            "stop_control": True,
            "stop_reason": "natural",
        }
        loop.observe_session(self.event, self.state)
        self.spec = {
            "workspace": str(self.root),
            "tasks": [
                {
                    "id": "first",
                    "title": "Fix code",
                    "criteria": [{"id": "works", "text": "works", "kind": "agent"}],
                    "commands": [
                        {
                            "argv": [
                                sys.executable,
                                "-c",
                                'import pathlib; assert pathlib.Path("code.txt").read_text()=="fixed\\n"',
                            ],
                            "timeout": 5,
                        }
                    ],
                }
            ],
        }

    def start(self):
        return loop.start(self.spec, "test", "s1", self.state)

    def stop(self, **kw):
        self.event.update(kw)
        return loop.handle_loop(self.event, {}, self.state)

    def tool(self):
        loop.handle_loop(dict(self.event, kind="post"), {}, self.state)

    def record(
        self, task="first", criterion="works", evidence="Implemented and inspected"
    ):
        return loop.record(
            self.root, task, criterion, evidence, "test", "s1", self.state
        )

    def test_explicit_start_identity_and_normal_mode(self):
        self.assertIsNone(self.stop())
        with self.assertRaises(loop.LoopError):
            loop.start(self.spec, "test", "invented", self.state)
        self.assertEqual(self.start()["state"], "running")
        with self.assertRaises(loop.LoopError):
            self.start()

    def test_multiple_corrections_then_final_all_check(self):
        self.start()
        self.assertEqual(self.stop()["action"], "continue")
        self.assertEqual(self.stop()["action"], "notify")
        self.tool()
        self.file.write_text("wrong\n")
        self.assertEqual(self.stop()["action"], "continue")
        self.tool()
        self.file.write_text("fixed\n")
        self.record()
        self.assertEqual(self.stop()["action"], "continue")  # fresh final generation
        self.tool()
        self.assertEqual(self.stop()["loop"]["state"], "completed")

    def test_three_no_progress_and_failed_check_retries(self):
        self.start()
        for _ in range(3):
            self.stop()
            self.tool()
        state = loop.status(self.root, self.state)
        self.assertEqual(state["state"], "blocked")
        self.assertEqual(state["check_runs"], 3)

    def test_content_cycle_blocks(self):
        self.start()
        for value in ["A", "B", "A", "B", "A", "B", "A"]:
            self.file.write_text(value)
            self.stop()
            self.tool()
            if loop.status(self.root, self.state)["state"] == "blocked":
                break
        self.assertEqual(loop.status(self.root, self.state)["state"], "blocked")

    def test_ordered_tasks_no_evidence_skip(self):
        self.spec["tasks"].append(
            {
                "id": "second",
                "title": "Second",
                "criteria": [{"id": "two", "text": "two"}],
                "commands": [],
            }
        )
        self.start()
        with self.assertRaises(loop.LoopError):
            self.record("second", "two")
        self.file.write_text("fixed\n")
        self.record()
        self.stop()
        self.assertEqual(loop.status(self.root, self.state)["current_task"], 1)

    def test_final_regression_reopens(self):
        self.start()
        self.file.write_text("fixed\n")
        self.record()
        self.stop()
        self.tool()
        self.file.write_text("regression\n")
        value = self.stop()
        self.assertEqual(value["loop"]["state"], "running")
        self.assertEqual(loop.status(self.root, self.state)["current_task"], 0)
        self.assertNotEqual(value["loop"]["state"], "completed")

    def test_pause_transfer_stale_owner_and_cancel(self):
        self.start()
        lease = loop.prepare_provider(self.event, "common", self.state)
        loop.control(self.root, "pause", state_dir=self.state)
        self.assertEqual(self.stop()["loop"]["state"], "paused")
        other = dict(self.event, session_id="s2")
        loop.observe_session(other, self.state)
        loop.control(self.root, "resume", "test", "s2", self.state)
        self.assertFalse(loop.submit_provider(lease, [], state_dir=self.state))
        self.assertIsNone(self.stop())
        loop.control(self.root, "cancel", state_dir=self.state)
        self.assertEqual(loop.status(self.root, self.state)["state"], "cancelled")

    def test_lifecycle_restart_and_new_user_input(self):
        self.start()
        self.stop()
        loop.handle_loop(dict(self.event, kind="start"), {}, self.state)
        self.assertEqual(loop.status(self.root, self.state)["state"], "paused")
        loop.control(self.root, "resume", "test", "s1", self.state)
        loop.handle_loop(
            dict(self.event, kind="prompt", prompt="change scope"), {}, self.state
        )
        self.assertEqual(loop.status(self.root, self.state)["state"], "waiting")

    def test_product_stops_and_background_excluded(self):
        self.start()
        self.assertEqual(self.stop(stop_reason="approval")["loop"]["state"], "waiting")
        loop.control(self.root, "resume", "test", "s1", self.state)
        self.assertEqual(
            self.stop(stop_reason="natural", origin="cron")["action"], "notify"
        )
        self.assertEqual(loop.status(self.root, self.state)["state"], "waiting")

    def test_provider_registration_and_fresh_final_generation(self):
        self.event["loop_provider"] = "ai"
        self.spec["providers"] = ["ai"]
        with self.assertRaises(loop.LoopError):
            self.start()
        loop.register_provider(self.root, "ai", self.state)
        self.start()
        self.file.write_text("fixed\n")
        self.record()
        self.assertTrue(self.stop()["pending"])
        self.assertEqual(loop.status(self.root, self.state)["state"], "running")
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db1")
        self.assertTrue(
            loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db1")
        )
        self.record()
        self.assertEqual(self.stop()["action"], "continue")
        self.tool()
        self.assertTrue(self.stop()["pending"])
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db1")
        self.assertTrue(
            loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db1")
        )
        self.assertEqual(self.stop()["loop"]["state"], "completed")

    def test_edit_during_check_and_lease_stale(self):
        self.start()
        lease = loop.prepare_provider(self.event, "common", self.state)
        self.assertIsNone(loop.prepare_provider(self.event, "common", self.state))
        self.file.write_text("edited\n")
        self.assertFalse(loop.submit_provider(lease, [], state_dir=self.state))
        self.assertEqual(loop.status(self.root, self.state)["results"], {})

    def test_external_fingerprint_change_invalidates_results(self):
        loop.register_provider(self.root, "ai", self.state)
        self.spec["providers"] = ["ai"]
        self.start()
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db1")
        self.assertFalse(
            loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db2")
        )
        self.assertEqual(loop.status(self.root, self.state)["results"], {})

    def test_command_runs_without_holding_state_lock(self):
        self.start()
        entered = threading.Event()
        release = threading.Event()
        failures = []

        def check(command, workspace):
            entered.set()
            if not release.wait(15):
                raise AssertionError("test never released check")

        def worker():
            try:
                self.stop()
            # Propagate every thread failure to the assertion in the main thread.
            except BaseException as exc:  # noqa: BLE001
                failures.append(exc)

        with mock.patch.object(loop, "_run_check", check):
            thread = threading.Thread(target=worker)
            thread.start()
            try:
                self.assertTrue(entered.wait(10))
                # check is still blocked: a state lock around it would time out.
                loop.control(self.root, "pause", state_dir=self.state)
            finally:
                release.set()
                thread.join(15)
            self.assertFalse(thread.is_alive())
            self.assertEqual(failures, [])
        self.assertEqual(loop.status(self.root, self.state)["state"], "paused")

    def test_uncertain_delivery_never_resends_and_old_request_rejected(self):
        self.start()
        value = self.stop()
        request = value["loop"]["request_id"]
        self.assertTrue(loop.claim_delivery(self.event, request, self.state))
        self.assertFalse(loop.claim_delivery(self.event, request, self.state))
        self.assertTrue(
            loop.finish_delivery(self.event, request, "unknown", self.state)
        )
        self.assertEqual(self.stop()["loop"]["state"], "waiting")
        loop.control(self.root, "resume", "test", "s1", self.state)
        self.assertFalse(loop.claim_delivery(self.event, request, self.state))

    def test_human_cannot_be_manufactured_by_agent_record(self):
        self.spec["tasks"][0]["criteria"][0]["kind"] = "human"
        self.start()
        self.file.write_text("fixed\n")
        with self.assertRaises(loop.LoopError):
            self.record()
        self.assertEqual(self.stop()["loop"]["state"], "waiting")
        loop.confirm_human(
            self.root,
            "first",
            "works",
            "I reviewed it and approve.",
            "user message 42",
            self.state,
        )
        loop.control(self.root, "resume", "test", "s1", self.state)
        self.assertEqual(self.stop()["action"], "continue")
        self.tool()
        self.assertEqual(self.stop()["loop"]["state"], "completed")

    def test_timeout_is_failure_not_completion(self):
        self.spec["tasks"][0]["commands"] = [
            {
                "argv": [sys.executable, "-c", "import time; time.sleep(5)"],
                "timeout": 0.1,
            }
        ]
        self.start()
        value = self.stop()
        self.assertEqual(value["action"], "continue")
        self.assertIn("timeout", value["message"].lower())

    def test_empty_criteria_or_unreviewed_scope_rejected(self):
        self.spec["tasks"][0]["criteria"] = []
        with self.assertRaises(loop.LoopError):
            self.start()

    def test_random_check_log_is_not_progress(self):
        self.spec["tasks"][0]["commands"] = [
            {
                "argv": [
                    sys.executable,
                    "-c",
                    "import time; print(time.time()); raise SystemExit(1)",
                ]
            }
        ]
        self.start()
        messages = []
        for _ in range(3):
            messages.append(self.stop()["issues"][0]["message"])
            self.tool()
        self.assertNotEqual(messages[0], messages[1])
        self.assertEqual(loop.status(self.root, self.state)["state"], "blocked")

    def test_fewer_failed_commands_counts_as_progress(self):
        self.spec["tasks"][0]["commands"] = [
            {"argv": [sys.executable, "-c", "raise SystemExit(1)"]},
            {"argv": [sys.executable, "-c", "raise SystemExit(2)"]},
        ]
        self.start()
        self.stop()
        self.tool()
        self.stop()
        self.tool()
        real = loop._run_check

        def reduced(command, workspace):
            return (
                None
                if "SystemExit(2)" in command["argv"][-1]
                else real(command, workspace)
            )

        with mock.patch.object(loop, "_run_check", reduced):
            self.stop()
        self.assertEqual(loop.status(self.root, self.state)["state"], "running")

    def test_complete_two_tasks_after_final_current_evidence(self):
        self.spec["tasks"].append(
            {
                "id": "second",
                "title": "Later task",
                "criteria": [{"id": "two", "text": "second inspected"}],
                "commands": [
                    {
                        "argv": [
                            sys.executable,
                            "-c",
                            'import pathlib; assert pathlib.Path("later.txt").exists()',
                        ]
                    }
                ],
            }
        )
        self.start()
        self.file.write_text("fixed\n")
        self.record()
        self.stop()
        self.tool()
        (self.root / "later.txt").write_text("later change\n")
        self.record("second", "two")
        self.stop()
        self.tool()
        value = self.stop()
        self.assertIn("first/works", value["message"])
        self.tool()
        self.record()
        self.assertEqual(self.stop()["loop"]["state"], "completed")

    def test_later_task_breaks_earlier_check_in_final_pass(self):
        self.spec["tasks"].append(
            {
                "id": "second",
                "title": "Later task",
                "criteria": [{"id": "two", "text": "later"}],
                "commands": [],
            }
        )
        self.start()
        self.file.write_text("fixed\n")
        self.record()
        self.stop()
        self.tool()
        self.file.write_text("regression\n")
        self.record("second", "two")
        self.stop()
        self.tool()
        self.stop()
        state = loop.status(self.root, self.state)
        self.assertEqual(state["phase"], "tasks")
        self.assertEqual(state["current_task"], 0)
        self.assertNotIn("first/works", state["evidence"])

    def test_no_tool_native_continuation_admission_and_dedup(self):
        self.start()
        value = self.stop()
        event = dict(self.event, kind="prompt", prompt=value["message"])
        self.assertEqual(
            loop.handle_loop(event, {}, self.state)["loop"]["state"], "running"
        )
        second = self.stop()
        self.assertEqual(second["action"], "continue")
        self.assertEqual(self.stop()["action"], "notify")
        self.assertNotEqual(value["loop"]["request_id"], second["loop"]["request_id"])

    def test_distinct_native_stop_observation_can_retry_without_tools(self):
        self.start()
        self.assertEqual(self.stop(loop_stop_id="assistant1")["action"], "continue")
        self.assertEqual(self.stop()["action"], "notify")
        self.assertEqual(self.stop(loop_stop_id="assistant2")["action"], "continue")
        self.assertEqual(
            self.stop(loop_stop_id="assistant3")["loop"]["state"], "blocked"
        )

    def test_changed_during_real_check_requests_recheck(self):
        self.spec["tasks"][0]["commands"] = [
            {
                "argv": [
                    sys.executable,
                    "-c",
                    'import pathlib; pathlib.Path("code.txt").write_text("changed")',
                ]
            }
        ]
        self.start()
        result = self.stop()
        self.assertEqual(result["action"], "continue")
        self.assertTrue(result["pending"])
        self.assertNotEqual(result["loop"]["state"], "completed")

    def test_external_content_stales_evidence_and_global_cannot_advance(self):
        loop.register_provider(self.root, "ai", self.state)
        self.start()
        self.file.write_text("fixed\n")
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db1")
        loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db1")
        self.record()
        self.assertEqual(self.stop()["action"], "notify")
        self.assertEqual(loop.status(self.root, self.state)["current_task"], 0)
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db2")
        loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db2")
        value = self.stop(loop_provider="ai")
        self.assertIn("first/works", value["message"])

    def test_unrelated_session_keeps_normal_audit_and_guards(self):
        import common_hook

        self.start()
        other = dict(
            self.event,
            harness="test",
            session_id="unrelated",
            kind="pre",
            command="git reset --hard",
        )
        self.assertEqual(
            common_hook.handle_event(other, state_dir=self.state)["action"], "deny"
        )
        self.assertIsNone(loop.handle_loop(dict(other, kind="stop"), {}, self.state))
        other.update(kind="pre", command="true")
        common_hook.handle_event(other, state_dir=self.state)
        self.file.write_text("new content   \n")
        ordinary = common_hook.handle_event(
            dict(other, kind="stop"), state_dir=self.state
        )
        self.assertEqual(ordinary["action"], "continue")
        self.assertNotIn("loop", ordinary)
        self.assertEqual(loop.status(self.root, self.state)["state"], "running")

    def test_cli_entrypoint_and_unobserved_identity(self):
        spec = Path(self.tmp.name) / "spec.json"
        spec.write_text(json.dumps(self.spec))
        entry = HOOKS / "agent-loop"
        args = [
            str(entry),
            "--state-dir",
            str(self.state),
            "start",
            "--spec",
            str(spec),
            "--harness",
            "test",
            "--session",
        ]
        failed = subprocess.run(
            args + ["invented"], capture_output=True, text=True, check=False
        )
        self.assertEqual(failed.returncode, 2)
        started = subprocess.run(
            args + ["s1"], capture_output=True, text=True, check=False
        )
        self.assertEqual(started.returncode, 0, started.stderr)
        self.assertEqual(json.loads(started.stdout)["state"], "running")
        loop_id = json.loads(started.stdout)["id"]
        checked = subprocess.run(
            [
                str(entry),
                "--state-dir",
                str(self.state),
                "check",
                "--loop-id",
                loop_id,
                "--workspace",
                str(self.root),
                "--harness",
                "test",
                "--session",
                "s1",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertTrue(json.loads(checked.stdout)["issues"])

    def test_dead_provider_lease_waits_for_explicit_resume(self):
        self.start()
        lease = loop.prepare_provider(self.event, "common", self.state)
        with loop._locked(self.root, self.state) as ledger:
            ledger["loop"]["leases"]["common"]["checker_pid"] = 2147483647
        self.assertIsNone(loop.prepare_provider(self.event, "common", self.state))
        self.assertEqual(loop.status(self.root, self.state)["state"], "waiting")
        loop.control(self.root, "resume", "test", "s1", self.state)
        self.assertFalse(loop.submit_provider(lease, [], state_dir=self.state))
        self.assertIsNotNone(loop.prepare_provider(self.event, "common", self.state))

    def test_cli_cannot_bypass_basic_whitespace_gate(self):
        self.spec["tasks"][0]["commands"] = []
        self.start()
        self.file.write_text("bad whitespace   \n")
        self.record()
        entry = HOOKS / "agent-loop"
        argv = [
            str(entry),
            "--state-dir",
            str(self.state),
            "check",
            "--loop-id",
            loop.status(self.root, self.state)["id"],
            "--workspace",
            str(self.root),
            "--harness",
            "test",
            "--session",
            "s1",
        ]
        for _ in range(2):
            value = subprocess.run(argv, capture_output=True, text=True, check=False)
            self.assertEqual(value.returncode, 0, value.stderr)
            self.assertNotEqual(json.loads(value.stdout)["loop"]["state"], "completed")
            self.assertTrue(json.loads(value.stdout)["issues"])

    def test_kiro_native_notification_waits_but_manual_check_does_not(self):
        event = dict(
            self.event, harness="kiro", session_id="kiro-session", stop_control=False
        )
        loop.observe_session(event, self.state)
        loop.start(self.spec, "kiro", "kiro-session", self.state)
        result = loop.handle_loop(event, {}, self.state)
        self.assertEqual(result["loop"]["state"], "waiting")
        loop.control(self.root, "resume", "kiro", "kiro-session", self.state)
        result = loop.handle_loop(dict(event, manual_check=True), {}, self.state)
        self.assertEqual(result["loop"]["state"], "running")

    def test_explicit_log_artifact_bytes_do_not_count_as_progress(self):
        self.spec["artifact_paths"] = ["logs"]
        self.start()
        logs = self.root / "logs"
        logs.mkdir()
        fingerprints = []
        for attempt in range(3):
            (logs / "run.log").write_text(str(time.time()))
            value = self.stop()
            fingerprints.append(value["loop"]["fingerprint"])
            self.tool()
        self.assertEqual(len(set(fingerprints)), 1)
        self.assertEqual(loop.status(self.root, self.state)["state"], "blocked")

    def test_loop_state_inside_workspace_is_explicitly_excluded(self):
        self.state = self.root / "loop-state"
        loop.observe_session(self.event, self.state)
        self.start()
        self.file.write_text("fixed\n")
        self.record()
        self.assertEqual(self.stop()["action"], "continue")
        self.tool()
        self.assertEqual(self.stop()["loop"]["state"], "completed")

    def test_duplicate_delivery_validation_does_not_claim_twice(self):
        self.start()
        value = self.stop()
        request = value["loop"]["request_id"]
        self.assertFalse(loop.validate_delivery(self.event, request, self.state))
        self.assertTrue(loop.claim_delivery(self.event, request, self.state))
        self.assertTrue(loop.validate_delivery(self.event, request, self.state))
        self.assertTrue(loop.validate_delivery(self.event, request, self.state))
        self.assertFalse(loop.claim_delivery(self.event, request, self.state))
        self.file.write_text("edited\n")
        self.assertFalse(loop.validate_delivery(self.event, request, self.state))

    def test_async_external_change_revokes_request_before_claim(self):
        loop.register_provider(self.root, "ai", self.state)
        self.start()
        lease = loop.prepare_provider(self.event, "ai", self.state, fingerprint="db1")
        loop.submit_provider(lease, [], state_dir=self.state, fingerprint="db1")
        value = self.stop(loop_provider="ai")
        request = value["loop"]["request_id"]
        self.assertTrue(
            loop.refresh_provider_content(self.event, "ai", "db1", self.state)
        )
        self.assertFalse(
            loop.refresh_provider_content(self.event, "ai", "db2", self.state)
        )
        self.assertFalse(loop.claim_delivery(self.event, request, self.state))
        self.assertEqual(loop.status(self.root, self.state)["results"], {})

    def test_durable_terminal_sequence_replay_rejected(self):
        self.start()
        first = self.stop(stop_event_id="evt1", stop_event_seq=10)
        self.assertEqual(first["action"], "continue")
        second = self.stop(stop_event_id="evt2", stop_event_seq=11)
        self.assertEqual(second["action"], "continue")
        replay = self.stop(stop_event_id="evt1", stop_event_seq=10)
        self.assertEqual(replay["action"], "notify")
        self.assertEqual(replay["loop"]["request_id"], second["loop"]["request_id"])
        self.assertEqual(
            self.stop(stop_event_id="evt3", stop_event_seq=12)["loop"]["state"],
            "blocked",
        )

    def test_same_session_resume_rejects_old_checker_and_result(self):
        self.start()
        entered = threading.Event()
        release = threading.Event()
        results = []
        failures = []

        def check(command, workspace):
            entered.set()
            release.wait(15)

        def worker():
            try:
                results.append(self.stop())
            # Propagate every thread failure to the assertion in the main thread.
            except BaseException as exc:  # noqa: BLE001
                failures.append(exc)

        with mock.patch.object(loop, "_run_check", check):
            thread = threading.Thread(target=worker)
            thread.start()
            try:
                self.assertTrue(entered.wait(10))
                loop.control(self.root, "pause", state_dir=self.state)
                adopted = loop.control(self.root, "resume", "test", "s1", self.state)
            finally:
                release.set()
                thread.join(15)
        self.assertFalse(thread.is_alive())
        self.assertEqual(failures, [])
        self.assertEqual(results[0]["action"], "notify")
        state = loop.status(self.root, self.state)
        self.assertEqual(state["owner_epoch"], adopted["owner_epoch"])
        self.assertEqual(state["check_runs"], 0)
        self.assertEqual(state["results"], {})
        self.assertIsNone(state["request"])

    def test_cli_stale_loop_id_cannot_mutate_replacement(self):
        old_id = self.start()["id"]
        loop.control(self.root, "cancel", state_dir=self.state)
        new_id = self.start()["id"]
        entry = HOOKS / "agent-loop"
        result = subprocess.run(
            [
                str(entry),
                "--state-dir",
                str(self.state),
                "pause",
                "--workspace",
                str(self.root),
                "--loop-id",
                old_id,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertEqual(loop.status(self.root, self.state)["id"], new_id)
        self.assertEqual(loop.status(self.root, self.state)["state"], "running")

    def test_dead_native_host_cannot_silently_resume(self):
        event = dict(self.event, host_pid=os.getpid())
        loop.observe_session(event, self.state)
        self.start()
        with loop._locked(self.root, self.state) as ledger:
            ledger["loop"]["host_pid"] = 2147483647
        self.assertEqual(loop.status(self.root, self.state)["state"], "paused")
        replacement = loop.handle_loop(event, {}, self.state)
        self.assertEqual(replacement["loop"]["state"], "paused")
        loop.control(self.root, "resume", "test", "s1", self.state)
        self.assertEqual(loop.status(self.root, self.state)["state"], "running")

    def test_skill_example_spec_and_commands_are_runnable(self):
        skill = (HOOKS.parent / "skills/agent-loop/SKILL.md").read_text()
        script = skill.split("python3 - <<'PY'\n", 1)[1].split("\nPY\n", 1)[0]
        spec_path = Path(self.tmp.name) / "skill-spec.json"
        script = script.replace("'/tmp/agent-loop-spec.json'", repr(str(spec_path)))
        generated = subprocess.run(
            [sys.executable, "-c", script],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(generated.returncode, 0, generated.stderr)
        test_dir = self.root / "tests"
        test_dir.mkdir()
        (test_dir / "test_example.py").write_text(
            "import unittest\nclass Example(unittest.TestCase):\n    def test_true(self):\n        self.assertTrue(True)\n"
        )
        value = loop.start(json.loads(spec_path.read_text()), "test", "s1", self.state)
        self.assertEqual(value["tasks"][0]["id"], "repair")
        loop.record(
            self.root,
            "repair",
            "behavior",
            "Observed approved behavior and unittest success",
            "test",
            "s1",
            self.state,
        )
        self.assertEqual(self.stop()["action"], "continue")
        self.tool()
        self.assertEqual(self.stop()["loop"]["state"], "completed")


if __name__ == "__main__":
    unittest.main()
