"""Explicit development loops. No loop is inferred from a hook or user prose.

The local account is the trust boundary: native hooks observe session identities,
reviewed specs select commands, and project hooks register providers. This is an
orchestration/evidence ledger, not a shell sandbox or human authentication system.
"""

import argparse
import contextlib
import fcntl
import hashlib
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

VERSION = 1
TERMINAL = {"cancelled", "completed"}
ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}$")


class LoopError(ValueError):
    pass


def _workspace(workspace):
    path = Path(workspace).expanduser().resolve()
    if not path.is_dir():
        raise LoopError("Workspace does not exist")
    return path


def _base(state_dir=None):
    base = state_dir or os.environ.get("AGENT_HOOK_STATE_DIR")
    if base is None:
        base = (
            Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
            / "agents/hooks"
        )
    return Path(base).expanduser() / "loops"


def _location(workspace, state_dir=None):
    return (
        _base(state_dir)
        / hashlib.sha256(str(_workspace(workspace)).encode()).hexdigest()
    )


@contextlib.contextmanager
def _locked(workspace, state_dir=None):
    location = _location(workspace, state_dir)
    location.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (location / "lock").open("a+") as stream:
        deadline = time.monotonic() + 2
        while True:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise LoopError("Loop state lock timeout")
                time.sleep(0.01)
        try:
            path = location / "ledger.json"
            try:
                ledger = (
                    json.loads(path.read_text())
                    if path.exists()
                    else {"sessions": {}, "providers": []}
                )
            except (OSError, ValueError) as exc:
                raise LoopError(f"Cannot read loop state: {exc}") from exc
            yield ledger
            fd, temporary = tempfile.mkstemp(prefix=".ledger-", dir=location)
            try:
                with os.fdopen(fd, "w") as writer:
                    json.dump(ledger, writer, sort_keys=True)
                    writer.flush()
                    os.fsync(writer.fileno())
                os.replace(temporary, path)
            finally:
                with contextlib.suppress(FileNotFoundError):
                    os.unlink(temporary)
        finally:
            fcntl.flock(stream, fcntl.LOCK_UN)


def _identity(harness, session):
    if (
        not isinstance(harness, str)
        or not harness.strip()
        or not isinstance(session, str)
        or not session.strip()
    ):
        raise LoopError("Authoritative harness and session identity required")
    return json.dumps([harness, session])


def observe_session(event, state_dir=None):
    harness, session = event.get("harness"), event.get("session_id")
    if (
        not isinstance(harness, str)
        or not harness.strip()
        or not isinstance(session, str)
        or not session.strip()
    ):
        return False
    workspace = _workspace(event["workspace"])
    with _locked(workspace, state_dir) as ledger:
        observed = {
            "harness": harness,
            "session_id": session,
            "observed_at": time.time(),
        }
        host_pid = event.get("host_pid")
        if (
            isinstance(host_pid, int)
            and not isinstance(host_pid, bool)
            and host_pid > 0
        ):
            observed.update(host_pid=host_pid, host_start=_process_start(host_pid))
        elif ledger["sessions"].get(_identity(harness, session), {}).get("host_pid"):
            previous = ledger["sessions"][_identity(harness, session)]
            observed.update(
                host_pid=previous["host_pid"], host_start=previous.get("host_start")
            )
        ledger["sessions"][_identity(harness, session)] = observed
    return True


def identities(workspace, state_dir=None):
    if not (_location(workspace, state_dir) / "ledger.json").exists():
        return []
    with _locked(workspace, state_dir) as ledger:
        return list(ledger["sessions"].values())


def register_provider(workspace, name, state_dir=None):
    if not isinstance(name, str) or not ID.fullmatch(name) or name == "common":
        raise LoopError("Invalid external provider name")
    with _locked(workspace, state_dir) as ledger:
        if name not in ledger["providers"]:
            ledger["providers"].append(name)
            state = ledger.get("loop")
            if (
                state
                and state["state"] not in TERMINAL
                and name not in state["providers"]
            ):
                _hold(
                    state,
                    "paused",
                    "New project provider registered; explicitly resume to include it",
                )
    return True


def _validate_spec(spec):
    if not isinstance(spec, dict):
        raise LoopError("Loop spec must be an object")
    workspace = _workspace(spec.get("workspace", ""))
    tasks = spec.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        raise LoopError("At least one ordered task required")
    tasks = json.loads(json.dumps(tasks))
    task_ids = set()
    for task in tasks:
        if (
            not isinstance(task, dict)
            or not ID.fullmatch(str(task.get("id", "")))
            or task["id"] in task_ids
        ):
            raise LoopError("Tasks require distinct IDs")
        task_ids.add(task["id"])
        if not isinstance(task.get("title"), str) or not task["title"].strip():
            raise LoopError("Task title required")
        criteria = task.get("criteria")
        if not isinstance(criteria, list) or not criteria:
            raise LoopError("Each task requires acceptance criteria")
        criterion_ids = set()
        for criterion in criteria:
            if (
                not isinstance(criterion, dict)
                or not ID.fullmatch(str(criterion.get("id", "")))
                or criterion["id"] in criterion_ids
            ):
                raise LoopError("Criteria require distinct IDs within a task")
            criterion_ids.add(criterion["id"])
            if (
                not isinstance(criterion.get("text"), str)
                or not criterion["text"].strip()
            ):
                raise LoopError("Criterion text required")
            criterion.setdefault("kind", "agent")
            if criterion["kind"] not in {"agent", "human"}:
                raise LoopError("Criterion kind must be agent or human")
        commands = task.setdefault("commands", [])
        if not isinstance(commands, list):
            raise LoopError("Commands must be explicit argv entries")
        for command in commands:
            argv = command.get("argv") if isinstance(command, dict) else None
            if (
                not isinstance(argv, list)
                or not argv
                or any(
                    not isinstance(arg, str) or not arg or "\0" in arg for arg in argv
                )
            ):
                raise LoopError("Commands require nonempty argv strings")
            if any(
                arg in {"--fix", "--fix-only", "--write", "--auto-fix"} for arg in argv
            ):
                raise LoopError("Checks cannot request automatic fixes")
            if Path(argv[0]).name == "git" and any(
                arg
                in {"add", "commit", "reset", "clean", "push", "checkout", "restore"}
                for arg in argv[1:]
            ):
                raise LoopError("Checks cannot mutate Git content")
            timeout = command.setdefault("timeout", 20)
            if (
                isinstance(timeout, bool)
                or not isinstance(timeout, (int, float))
                or not 0 < timeout <= 600
            ):
                raise LoopError(
                    "Each command timeout must be between 0 and 600 seconds"
                )
    providers = spec.get("providers", [])
    if not isinstance(providers, list) or any(
        not isinstance(name, str) or not ID.fullmatch(name) for name in providers
    ):
        raise LoopError("Providers must be explicit names")
    artifact_paths = spec.get("artifact_paths", [])
    if not isinstance(artifact_paths, list) or any(
        not isinstance(name, str)
        or not name
        or Path(name).is_absolute()
        or ".." in Path(name).parts
        or str(Path(name)) == "."
        for name in artifact_paths
    ):
        raise LoopError("Artifact paths must be explicit relative file/directory names")
    return workspace, tasks, providers, artifact_paths


def _git(workspace, argv):
    proc = subprocess.run(
        [
            "git",
            "--no-optional-locks",
            "-c",
            "core.fsmonitor=false",
            "-c",
            "core.hooksPath=/dev/null",
            *argv,
        ],
        cwd=workspace,
        capture_output=True,
        timeout=10,
        check=False,
    )
    return proc.returncode, proc.stdout


def content_fingerprint(workspace, state_dir=None, artifact_paths=None):
    """Hash HEAD, index entries and real file bytes, never mtimes or log output.

    Git ignores are the explicit artifact exclusion policy. Non-Git workspaces
    are rejected rather than implicitly walking arbitrary files or hidden state.
    External/ignored project data must be supplied by a registered provider.
    """
    workspace = _workspace(workspace)
    if artifact_paths is None:
        artifact_paths = status(workspace, state_dir).get("artifact_paths", [])
    excluded = [Path(name).as_posix().rstrip("/") for name in artifact_paths]
    explicit_state = _base(state_dir).parent.resolve()
    if explicit_state == workspace:
        raise LoopError("State directory cannot be the workspace root")
    if explicit_state.is_relative_to(workspace):
        excluded.append(explicit_state.relative_to(workspace).as_posix())

    def excluded_path(name):
        return any(
            name == prefix or name.startswith(prefix + "/") for prefix in excluded
        )

    code, names = _git(
        workspace, ["ls-files", "-z", "--cached", "--others", "--exclude-standard"]
    )
    if code:
        raise LoopError(
            "Explicit loops require a Git workspace; register external data through a provider"
        )
    code, index = _git(workspace, ["ls-files", "--stage", "-z"])
    if code:
        raise LoopError("Cannot inspect index")
    _, head = _git(workspace, ["rev-parse", "HEAD"])
    index = b"\0".join(
        entry
        for entry in index.split(b"\0")
        if entry and not excluded_path(os.fsdecode(entry.split(b"\t", 1)[-1]))
    )
    digest = hashlib.sha256(head + b"\0" + index)
    paths = sorted(
        {
            os.fsdecode(name)
            for name in names.split(b"\0")
            if name and not excluded_path(os.fsdecode(name))
        }
    )
    if len(paths) > 20000:
        raise LoopError("Workspace exceeds content fingerprint file limit")
    size = 0
    for name in paths:
        path = workspace / name
        if path.is_symlink():
            data = b"link:" + os.fsencode(os.readlink(path))
        elif path.is_file():
            if path.stat().st_size > 64 * 1024 * 1024:
                raise LoopError(f"Content fingerprint file too large: {name}")
            data = b"file:" + path.read_bytes()
        elif not path.exists():
            data = b"deleted"
        elif path.is_dir():
            # Gitlinks: submodule HEAD plus status must be reflected by provider
            # or explicit task commands, not silently traversed.
            code, data = _git(path, ["rev-parse", "HEAD"])
            if code:
                raise LoopError(f"Cannot fingerprint Gitlink: {name}")
            _, dirty = _git(path, ["status", "--porcelain"])
            if dirty:
                raise LoopError(
                    f"Dirty submodule requires a registered content provider: {name}"
                )
        else:
            raise LoopError(f"Cannot fingerprint file: {name}")
        size += len(data)
        if size > 512 * 1024 * 1024:
            raise LoopError("Workspace exceeds content fingerprint size limit")
        digest.update(os.fsencode(name) + b"\0" + data + b"\0")
    return digest.hexdigest()


def _combined(content, external):
    return hashlib.sha256(
        json.dumps([content, external], sort_keys=True).encode()
    ).hexdigest()


def _invalidate(state, content=None, external=None, force=False):
    content = content if content is not None else state["content"]
    external = external if external is not None else state["external_fingerprints"]
    fingerprint = _combined(content, external)
    if force or fingerprint != state["fingerprint"]:
        state.update(
            content=content,
            external_fingerprints=external,
            fingerprint=fingerprint,
            generation=state["generation"] + 1,
            results={},
            leases={},
        )
        state["request"] = None
        return True
    return False


def start(spec, harness, session, state_dir=None):
    workspace, tasks, requested, artifact_paths = _validate_spec(spec)
    identity = _identity(harness, session)
    content = content_fingerprint(
        workspace, state_dir=state_dir, artifact_paths=artifact_paths
    )
    with _locked(workspace, state_dir) as ledger:
        if identity not in ledger["sessions"]:
            raise LoopError(
                "Session has not been observed by a native hook; use agent-loop identity"
            )
        existing = ledger.get("loop")
        if existing and existing["state"] not in TERMINAL:
            raise LoopError(
                "A loop already exists; resume, pause or cancel it explicitly"
            )
        observed = ledger["sessions"][identity]
        if observed.get("host_pid") and not _lease_alive(
            {
                "checker_pid": observed["host_pid"],
                "checker_start": observed.get("host_start"),
            }
        ):
            raise LoopError(
                "Observed native host exited; establish a live session before starting"
            )
        registered = set(ledger["providers"]) | {"common"}
        if set(requested) - registered:
            raise LoopError("Unregistered project provider in spec")
        state = {
            "version": VERSION,
            "id": str(uuid.uuid4()),
            "workspace": str(workspace),
            "harness": harness,
            "session_id": session,
            "host_pid": observed.get("host_pid"),
            "host_start": observed.get("host_start"),
            "owner_epoch": 1,
            "state": "running",
            "tasks": tasks,
            "artifact_paths": artifact_paths,
            "providers": sorted(registered),
            "decision_provider": max(registered - {"common"})
            if registered - {"common"}
            else "common",
            "current_task": 0,
            "completed_tasks": [],
            "evidence": {},
            "results": {},
            "leases": {},
            "generation": 1,
            "content": content,
            "external_fingerprints": {},
            "fingerprint": _combined(content, {}),
            "phase": "tasks",
            "request": None,
            "history": [],
            "no_progress": 0,
            "check_runs": 0,
            "reason": "",
            "created_at": time.time(),
        }
        ledger["loop"] = state
        return json.loads(json.dumps(state))


def status(workspace, state_dir=None):
    if not (_location(workspace, state_dir) / "ledger.json").exists():
        return {}
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop", {})
        if (
            state
            and state["state"] == "running"
            and state.get("host_pid")
            and not _lease_alive(
                {
                    "checker_pid": state["host_pid"],
                    "checker_start": state.get("host_start"),
                }
            )
        ):
            _hold(
                state,
                "paused",
                "Native host exited; observe a live replacement and explicitly resume",
            )
        return json.loads(json.dumps(state))


def _owner(state, event):
    return (
        event.get("harness") == state["harness"]
        and event.get("session_id") == state["session_id"]
        and event.get("loop_id", state["id"]) == state["id"]
        and event.get("owner_epoch", state["owner_epoch"]) == state["owner_epoch"]
    )


def _hold(state, kind, reason):
    state.update(state=kind, reason=reason, request=None, leases={})


def control(
    workspace, action, harness=None, session=None, state_dir=None, loop_id=None
):
    content = (
        content_fingerprint(workspace, state_dir=state_dir)
        if action == "resume"
        else None
    )
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if not state:
            raise LoopError("No explicit loop exists")
        if loop_id is not None and state["id"] != loop_id:
            raise LoopError("Stale loop ID rejected")
        if state["state"] in TERMINAL:
            raise LoopError("Terminal loop cannot resume or change state")
        if action == "resume":
            identity = _identity(harness, session)
            if identity not in ledger["sessions"]:
                raise LoopError("Resume owner must be a native-observed session")
            observed = ledger["sessions"][identity]
            if observed.get("host_pid") and not _lease_alive(
                {
                    "checker_pid": observed["host_pid"],
                    "checker_start": observed.get("host_start"),
                }
            ):
                raise LoopError("Resume requires a live observed native host")
            if harness != state["harness"] or session != state["session_id"]:
                state.pop("active_stop_seq", None)
                state.pop("decided_stop_seq", None)
            state.update(
                harness=harness,
                session_id=session,
                host_pid=observed.get("host_pid"),
                host_start=observed.get("host_start"),
                owner_epoch=state["owner_epoch"] + 1,
                state="running",
                reason="",
                no_progress=0,
                history=[],
                request=None,
                providers=sorted(set(ledger["providers"]) | {"common"}),
                decision_provider=max(ledger["providers"])
                if ledger["providers"]
                else "common",
            )
            _invalidate(state, content=content, force=True)
        elif action in {"pause", "cancel"}:
            _hold(
                state,
                "paused" if action == "pause" else "cancelled",
                "Explicit user " + action,
            )
            state["owner_epoch"] += 1
        else:
            raise LoopError("Unknown loop control action")
        return json.loads(json.dumps(state))


def _process_start(pid):
    try:
        # Linux process start ticks distinguish PID reuse. Other hosts retain
        # conservative live-PID leases and always allow explicit resume.
        return Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[19]
    except OSError, IndexError:
        return None


def _lease_alive(lease):
    pid = lease.get("checker_pid")
    if not isinstance(pid, int) or pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    expected = lease.get("checker_start")
    actual = _process_start(pid)
    return expected is None or actual is None or expected == actual


def prepare_provider(event, provider, state_dir=None, fingerprint=None):
    workspace = _workspace(event["workspace"])
    prior_state = status(workspace, state_dir)
    if (
        not prior_state
        or prior_state["state"] != "running"
        or not _owner(prior_state, event)
    ):
        return None
    event = dict(
        event, loop_id=prior_state["id"], owner_epoch=prior_state["owner_epoch"]
    )
    content = content_fingerprint(workspace, state_dir=state_dir)
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if (
            not state
            or state["state"] != "running"
            or not _owner(state, event)
            or provider not in state["providers"]
        ):
            return None
        external = dict(state["external_fingerprints"])
        if fingerprint is not None and provider != "common":
            if not isinstance(fingerprint, str) or not fingerprint:
                raise LoopError("External fingerprint must be nonempty")
            external[provider] = fingerprint
        _invalidate(state, content, external)
        if provider in state["leases"]:
            if not _lease_alive(state["leases"][provider]):
                _hold(
                    state,
                    "waiting",
                    "Check provider process exited with an unfinished lease; inspect and explicitly resume",
                )
            return None
        prior = state["results"].get(provider)
        if (
            prior
            and not prior["issues"]
            and not prior["pending"]
            and not event.get("refresh_provider")
        ):
            return None
        lease = {
            "workspace": str(workspace),
            "loop_id": state["id"],
            "owner_epoch": state["owner_epoch"],
            "generation": state["generation"],
            "fingerprint": state["fingerprint"],
            "provider": provider,
            "harness": state["harness"],
            "session_id": state["session_id"],
            "lease_id": str(uuid.uuid4()),
            "checker_pid": os.getpid(),
            "checker_start": _process_start(os.getpid()),
            "external_fingerprint": fingerprint,
            "task_ids": (
                [t["id"] for t in state["tasks"]]
                if state["phase"] == "final"
                else [state["tasks"][state["current_task"]]["id"]]
            ),
        }
        state["leases"][provider] = lease
        return dict(lease)


def refresh_provider_content(event, provider, fingerprint, state_dir=None):
    """Revalidate external content at an async delivery boundary, without a lease."""
    if not isinstance(fingerprint, str) or not fingerprint:
        raise LoopError("External fingerprint must be nonempty")
    before = status(event["workspace"], state_dir)
    if (
        not before
        or before["state"] != "running"
        or not _owner(before, event)
        or provider not in before["providers"]
        or provider == "common"
    ):
        return False
    content = content_fingerprint(event["workspace"], state_dir=state_dir)
    with _locked(event["workspace"], state_dir) as ledger:
        state = ledger.get("loop")
        if (
            not state
            or state["state"] != "running"
            or not _owner(state, event)
            or state["id"] != before["id"]
            or state["owner_epoch"] != before["owner_epoch"]
        ):
            return False
        external = dict(state["external_fingerprints"])
        external[provider] = fingerprint
        changed = _invalidate(state, content, external)
        if changed:
            _hold(
                state,
                "waiting",
                "External content changed before continuation delivery; inspect and explicitly resume",
            )
            state["needs_recheck"] = True
        return not changed


def submit_provider(lease, issues, pending=False, state_dir=None, fingerprint=None):
    if not isinstance(lease, dict):
        return False
    workspace = _workspace(lease["workspace"])
    content = content_fingerprint(workspace, state_dir=state_dir)
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if not state or state["state"] != "running" or not _owner(state, lease):
            return False
        external = dict(state["external_fingerprints"])
        provider = lease.get("provider")
        if fingerprint is not None and provider != "common":
            external[provider] = fingerprint
        _invalidate(state, content, external)
        if (
            state["leases"].get(provider) != lease
            or lease.get("generation") != state["generation"]
            or lease.get("fingerprint") != state["fingerprint"]
        ):
            state["needs_recheck"] = True
            return False
        if not isinstance(issues, list):
            raise LoopError("Provider issues must be a list")
        state["leases"].pop(provider)
        state["results"][provider] = {
            "issues": issues,
            "pending": bool(pending),
            "generation": state["generation"],
            "fingerprint": state["fingerprint"],
        }
        return True


def _criterion(state, task_id, criterion_id):
    for index, task in enumerate(state["tasks"]):
        if task["id"] == task_id:
            if state["phase"] != "final" and index > state["current_task"]:
                raise LoopError("Evidence cannot skip ordered tasks")
            for criterion in task["criteria"]:
                if criterion["id"] == criterion_id:
                    return criterion
    raise LoopError("Unknown task or criterion")


def _evidence_key(task, criterion):
    return task + "/" + criterion


def record(
    workspace, task, criterion, evidence, harness, session, state_dir=None, loop_id=None
):
    if not isinstance(evidence, str) or not evidence.strip():
        raise LoopError("Concrete criterion evidence required")
    content = content_fingerprint(workspace, state_dir=state_dir)
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if (
            not state
            or state["state"] != "running"
            or not _owner(
                state,
                {
                    "harness": harness,
                    "session_id": session,
                    **({"loop_id": loop_id} if loop_id is not None else {}),
                },
            )
        ):
            raise LoopError("Only the active loop owner can record agent evidence")
        target = _criterion(state, task, criterion)
        if target["kind"] == "human":
            raise LoopError(
                "Agent record cannot satisfy a human criterion; wait for actual user review"
            )
        _invalidate(state, content)
        state["evidence"][_evidence_key(task, criterion)] = {
            "text": evidence,
            "source": "agent",
            "content": state["content"],
            "fingerprint": state["fingerprint"],
            "created_at": time.time(),
        }
        return json.loads(json.dumps(state))


def confirm_human(
    workspace, task, criterion, quotation, reference, state_dir=None, loop_id=None
):
    """Record actual user confirmation. The caller must preserve user quotation.

    No OS authentication claim: agents sharing the account can call commands;
    the skill requires genuine user input and never labels this independent review.
    """
    if (
        not isinstance(quotation, str)
        or not quotation.strip()
        or not isinstance(reference, str)
        or not reference.strip()
    ):
        raise LoopError("Actual user quotation and confirmation reference required")
    content = content_fingerprint(workspace, state_dir=state_dir)
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if not state or state["state"] in TERMINAL:
            raise LoopError("No active loop to confirm")
        if loop_id is not None and state["id"] != loop_id:
            raise LoopError("Stale loop ID rejected")
        target = _criterion(state, task, criterion)
        if target["kind"] != "human":
            raise LoopError("Human confirmation is only for human criteria")
        _invalidate(state, content)
        state["evidence"][_evidence_key(task, criterion)] = {
            "text": quotation,
            "reference": reference,
            "source": "user_confirmation",
            "content": content,
            "fingerprint": state["fingerprint"],
            "created_at": time.time(),
        }
        return json.loads(json.dumps(state))


def _run_check(command, workspace):
    try:
        process = subprocess.Popen(
            command["argv"],
            cwd=workspace,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
        try:
            out, err = process.communicate(timeout=command.get("timeout", 20))
        except subprocess.TimeoutExpired:
            with contextlib.suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            return "Check timeout: " + " ".join(command["argv"])
        if process.returncode:
            return (
                f"Check failed ({process.returncode}): "
                + " ".join(command["argv"])
                + "\n"
                + (out + err).decode(errors="replace")[-4000:]
            )
    except OSError as exc:
        return f"Cannot run check: {exc}"
    return None


def _result(state, action="notify", message="", issues=None, pending=False):
    value = {
        "action": action,
        "message": message or state.get("reason", ""),
        "issues": issues or [],
        "pending": pending,
        "loop": {
            "id": state["id"],
            "state": state["state"],
            "owner_epoch": state["owner_epoch"],
            "generation": state["generation"],
            "fingerprint": state["fingerprint"],
            "task": state["tasks"][min(state["current_task"], len(state["tasks"]) - 1)][
                "id"
            ],
        },
    }
    if state.get("request"):
        value["loop"]["request_id"] = state["request"]["id"]
    return value


def _continue(state, event, message, issues=None, pending=False):
    if not event.get("stop_control"):
        if event.get("harness") == "kiro" and not event.get("manual_check"):
            _hold(
                state,
                "waiting",
                "Kiro native continuation unavailable; inspect remaining task and explicitly resume. "
                + message,
            )
        return _result(state, "notify", message, issues, pending)
    if state.get("request"):
        return _result(
            state,
            "notify",
            "Continuation already requested; awaiting native work",
            issues,
            pending,
        )
    if isinstance(event.get("stop_event_seq"), int) and not isinstance(
        event.get("stop_event_seq"), bool
    ):
        state["decided_stop_seq"] = event["stop_event_seq"]
    state["request"] = {
        "id": str(uuid.uuid4()),
        "owner_epoch": state["owner_epoch"],
        "status": "prepared",
        "generation": state["generation"],
        "fingerprint": state["fingerprint"],
        "stop_id": event.get("loop_stop_id") or event.get("stop_event_id"),
    }
    message += "\n[agent-loop:" + state["id"] + ":" + state["request"]["id"] + "]"
    state["request"]["message"] = message
    return _result(state, "continue", message, issues, pending)


def _missing(state, task):
    missing = []
    for criterion in task["criteria"]:
        evidence = state["evidence"].get(_evidence_key(task["id"], criterion["id"]))
        expected_source = (
            "user_confirmation" if criterion["kind"] == "human" else "agent"
        )
        if (
            not evidence
            or evidence.get("fingerprint") != state["fingerprint"]
            or evidence["source"] != expected_source
        ):
            missing.append(criterion)
    return missing


def _progress(state, failure_ids=None):
    evidence = sorted(
        (key, value["text"])
        for key, value in state["evidence"].items()
        if value.get("fingerprint") == state["fingerprint"]
    )
    signature = hashlib.sha256(
        json.dumps(
            [
                state["fingerprint"],
                state["completed_tasks"],
                evidence,
                sorted(failure_ids or []),
            ],
            sort_keys=True,
        ).encode()
    ).hexdigest()
    if signature in state["history"]:
        state["no_progress"] += 1
    else:
        state["history"].append(signature)
        # Never count log/timestamp changes. A new real content/evidence state
        # is progress; revisiting a prior state detects oscillating repairs.
        state["no_progress"] = max(0, state["no_progress"] - 1)
    return state["no_progress"] >= 2  # initial attempt plus two recurrences


def handle_loop(event, policy=None, state_dir=None):
    workspace = _workspace(event["workspace"])
    observe_session(event, state_dir)
    kind = event.get("kind")
    with _locked(workspace, state_dir) as ledger:
        state = ledger.get("loop")
        if not state:
            return None
        if (
            event.get("harness") != state["harness"]
            or event.get("session_id") != state["session_id"]
        ):
            return None  # unrelated native sessions keep ordinary runtime behavior
        if not _owner(state, event):
            return _result(state, message="Stale loop ID or owner epoch rejected")
        if state["state"] in TERMINAL:
            return None
        if (
            state.get("host_pid")
            and event.get("host_pid")
            and (
                state["host_pid"] != event["host_pid"]
                or state.get("host_start") != _process_start(event["host_pid"])
            )
        ):
            _hold(
                state,
                "paused",
                "Native host changed; explicit ownership resume required",
            )
            return _result(state)
        if kind == "start":
            _hold(
                state,
                "paused",
                "Native session lifecycle started again; explicit resume required",
            )
            return _result(state)
        if kind == "end":
            if event.get("stop_reason") == "abort":
                _hold(
                    state,
                    "waiting",
                    "Native session interrupted; explicit resume required",
                )
            return _result(state)
        if kind == "prompt":
            if event.get("context_only"):
                return _result(state, "allow")
            # A self-delivered native continuation is not fresh human input.
            request = state.get("request") or {}
            native_request = event.get("loop_request_id") or event.get("request_id")
            if request and (
                native_request == request["id"]
                or event.get("prompt") == request.get("message")
            ):
                # Exact stored continuation admission (including unique marker),
                # never authorization inferred from arbitrary user prose.
                state["request"] = None
                _invalidate(state, force=True)
                state["needs_recheck"] = False
                return _result(state, "allow")
            _hold(
                state, "waiting", "New user input; review scope and explicitly resume"
            )
            return _result(state)
        if kind in {"pre", "post"}:
            if state["state"] == "running":
                _invalidate(state, force=True)
                state["needs_recheck"] = False
            return _result(state, "allow")
        if kind != "stop":
            return None
        if state["state"] != "running":
            return _result(state)
        # Bind this native event once: cancellation/replacement or transfer
        # during an external check cannot let an old callback adopt new state.
        event = dict(event, loop_id=state["id"], owner_epoch=state["owner_epoch"])
        sequence = event.get("stop_event_seq")
        if isinstance(sequence, int) and not isinstance(sequence, bool):
            active_sequence = state.get("active_stop_seq", -1)
            if sequence < active_sequence or sequence <= state.get(
                "decided_stop_seq", -1
            ):
                return _result(
                    state,
                    message="Duplicate or replayed native terminal event rejected",
                )
            state["active_stop_seq"] = sequence
        reason = event.get("stop_reason", "natural")
        origin = event.get("origin", "interactive")
        if reason != "natural" or origin != "interactive":
            _hold(
                state,
                "waiting",
                f"Product stop/origin {reason}/{origin}; explicit resume required",
            )
            return _result(state)
        if state.get("request"):
            stop_id = event.get("loop_stop_id") or event.get("stop_event_id")
            prior_id = state["request"].get("stop_id")
            if stop_id and prior_id and stop_id != prior_id:
                state["request"] = None
                _invalidate(state, force=True)
            else:
                return _result(
                    state,
                    message="Continuation already requested; awaiting native work",
                    pending=True,
                )
    # No lock is held while inspecting content or executing external commands.
    lease = prepare_provider(dict(event, refresh_provider=True), "common", state_dir)
    if lease:
        captured = status(workspace, state_dir)
        issues = []
        for task in captured["tasks"]:
            if task["id"] not in lease["task_ids"]:
                continue
            for command in task["commands"]:
                error = _run_check(command, workspace)
                if error:
                    issues.append(
                        {
                            "kind": "loop_check",
                            "task": task["id"],
                            "check_id": hashlib.sha256(
                                json.dumps(command["argv"]).encode()
                            ).hexdigest(),
                            "message": error,
                        }
                    )
        for command in (policy or {}).get("project_commands", []):
            error = _run_check(command, workspace)
            if error:
                issues.append(
                    {
                        "kind": "project_check",
                        "check_id": hashlib.sha256(
                            json.dumps(command["argv"]).encode()
                        ).hexdigest(),
                        "message": error,
                    }
                )
        # Basic conflict/whitespace checks remain baseline-aware in common_hook;
        # callers attach only the current common issues, not stale cached checks.
        issues.extend(event.get("common_issues", []))
        submit_provider(lease, issues, state_dir=state_dir)
        with _locked(workspace, state_dir) as ledger:
            current = ledger.get("loop")
            if (
                current
                and current["id"] == lease["loop_id"]
                and current["owner_epoch"] == lease["owner_epoch"]
            ):
                current["check_runs"] += 1
    content = content_fingerprint(workspace, state_dir=state_dir)
    with _locked(workspace, state_dir) as ledger:
        state = ledger["loop"]
        if not _owner(state, event) or state["state"] != "running":
            return _result(state)
        changed = _invalidate(state, content)
        if changed:
            return _continue(
                state,
                event,
                "Content changed during checks; run checks on current content again",
                pending=True,
            )
        coordinator = event.get("loop_provider", "common") == state["decision_provider"]
        if not coordinator:
            return _result(
                state,
                message="Awaiting fixed decision provider: "
                + state["decision_provider"],
                pending=True,
            )
        if any(provider not in state["results"] for provider in state["providers"]):
            if state.pop("needs_recheck", False):
                return _continue(
                    state,
                    event,
                    "Content changed during provider checks; rerun all current-content checks.",
                    pending=True,
                )
            return _result(
                state,
                message="Awaiting registered provider results: "
                + ", ".join(p for p in state["providers"] if p not in state["results"]),
                pending=True,
            )
        state["needs_recheck"] = False
        if isinstance(event.get("stop_event_seq"), int) and not isinstance(
            event.get("stop_event_seq"), bool
        ):
            state["decided_stop_seq"] = event["stop_event_seq"]
        if any(
            r["generation"] != state["generation"]
            or r["fingerprint"] != state["fingerprint"]
            for r in state["results"].values()
        ):
            return _result(
                state,
                message="Provider results are stale; run current checks again",
                pending=True,
            )
        issues = [issue for r in state["results"].values() for issue in r["issues"]]
        pending = any(r["pending"] for r in state["results"].values())
        task = state["tasks"][min(state["current_task"], len(state["tasks"]) - 1)]
        if issues or pending:
            if state["phase"] == "final":
                affected = {
                    issue.get("task")
                    for issue in issues
                    if isinstance(issue, dict) and issue.get("task")
                }
                if not affected:
                    affected = {t["id"] for t in state["tasks"]}
                state["current_task"] = min(
                    i for i, t in enumerate(state["tasks"]) if t["id"] in affected
                )
                state["completed_tasks"] = [
                    t["id"] for t in state["tasks"][: state["current_task"]]
                ]
                state["phase"] = "tasks"
                for key in list(state["evidence"]):
                    if key.split("/")[0] in affected:
                        state["evidence"].pop(key)
            failure_ids = [
                json.dumps(
                    [
                        provider,
                        item.get("kind"),
                        item.get("task"),
                        item.get("check_id"),
                        item.get("file"),
                        item.get("line"),
                    ],
                    sort_keys=True,
                )
                for provider, result in state["results"].items()
                for item in result["issues"]
                if isinstance(item, dict)
            ]
            if pending:
                failure_ids.append("pending")
            if _progress(state, failure_ids):
                _hold(
                    state,
                    "blocked",
                    "Same lack of progress occurred three times, including repeated content cycles",
                )
                return _result(state, issues=issues, pending=pending)
            state["results"] = {}  # Failed checks always rerun, even without edits.
            message = "\n".join(
                str(i.get("message", i)) if isinstance(i, dict) else str(i)
                for i in issues
            )
            return _continue(
                state,
                event,
                f"Loop {state['id']}: repair task {task['id']} ({task['title']}), then run agent-loop check and record concrete evidence for each criterion.\n"
                + message,
                issues,
                pending,
            )
        selected = state["tasks"] if state["phase"] == "final" else [task]
        missing = [(t, c) for t in selected for c in _missing(state, t)]
        if missing:
            if any(c["kind"] == "human" for _, c in missing):
                _hold(
                    state,
                    "waiting",
                    "Actual user review required: "
                    + ", ".join(
                        f"{t['id']}/{c['id']}: {c['text']}"
                        for t, c in missing
                        if c["kind"] == "human"
                    ),
                )
                return _result(state)
            if _progress(state):
                _hold(
                    state, "blocked", "Criterion evidence made no progress three times"
                )
                return _result(state)
            message = (
                "Record current-content criterion evidence with agent-loop record: "
                + "; ".join(f"{t['id']}/{c['id']}: {c['text']}" for t, c in missing)
            )
            return _continue(state, event, message)
        if state["phase"] == "final":
            state.update(
                state="completed",
                reason="All tasks, current criterion evidence and fresh final provider checks passed",
                request=None,
            )
            return _result(state, "allow", state["reason"])
        if task["id"] not in state["completed_tasks"]:
            state["completed_tasks"].append(task["id"])
        state["current_task"] += 1
        state.update(no_progress=0, history=[])
        if state["current_task"] >= len(state["tasks"]):
            state["phase"] = "final"
            state["current_task"] = len(state["tasks"]) - 1
            _invalidate(state, force=True)
            return _continue(
                state,
                event,
                "Run the fresh final pass of every registered check and confirm all acceptance evidence matches current content.",
                pending=True,
            )
        _invalidate(state, force=True)
        next_task = state["tasks"][state["current_task"]]
        return _continue(
            state,
            event,
            f"Continue ordered task {next_task['id']}: {next_task['title']}. Satisfy its criteria and record evidence.",
            pending=True,
        )


def claim_delivery(event, request_id, state_dir=None):
    content = content_fingerprint(event["workspace"], state_dir=state_dir)
    with _locked(event["workspace"], state_dir) as ledger:
        state = ledger.get("loop")
        if not state or state["state"] != "running" or not _owner(state, event):
            return False
        if _invalidate(state, content):
            _hold(
                state,
                "waiting",
                "Content changed before continuation claim; inspect and explicitly resume",
            )
            return False
        request = state.get("request")
        if (
            not request
            or request["id"] != request_id
            or request["status"] != "prepared"
        ):
            return False
        request["status"] = "claimed"
        return True


def validate_delivery(event, request_id, state_dir=None):
    """Read-only verification for duplicate native prompt admission callbacks."""
    content = content_fingerprint(event["workspace"], state_dir=state_dir)
    with _locked(event["workspace"], state_dir) as ledger:
        state = ledger.get("loop")
        if not state or state["state"] != "running" or not _owner(state, event):
            return False
        request = state.get("request")
        return bool(
            request
            and request["id"] == request_id
            and request["status"] in {"claimed", "accepted"}
            and request["owner_epoch"] == state["owner_epoch"]
            and request["generation"] == state["generation"]
            and request["fingerprint"]
            == _combined(content, state["external_fingerprints"])
        )


def finish_delivery(event, request_id, outcome, state_dir=None):
    if outcome not in {"accepted", "unknown", "aborted"}:
        raise LoopError("Invalid delivery outcome")
    with _locked(event["workspace"], state_dir) as ledger:
        state = ledger.get("loop")
        if not state or state["state"] != "running" or not _owner(state, event):
            return False
        request = state.get("request")
        if not request or request["id"] != request_id or request["status"] != "claimed":
            return False
        request["status"] = outcome
        if outcome != "accepted":
            _hold(
                state,
                "waiting",
                f"Continuation delivery {outcome}; do not resend, explicitly resume after inspection",
            )
        return True


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-dir")
    sub = parser.add_subparsers(dest="action", required=True)
    for name in [
        "identity",
        "status",
        "check",
        "pause",
        "resume",
        "cancel",
        "record",
        "confirm-human",
    ]:
        item = sub.add_parser(name)
        item.add_argument("--workspace", default=os.getcwd())
        if name not in {"identity", "status"}:
            item.add_argument("--loop-id", required=True)
        if name in {"resume", "record", "check"}:
            item.add_argument("--harness", required=True)
            item.add_argument("--session", required=True)
        if name in {"record", "confirm-human"}:
            item.add_argument("--task", required=True)
            item.add_argument("--criterion", required=True)
        if name == "record":
            item.add_argument("--evidence", required=True)
        if name == "confirm-human":
            item.add_argument("--quotation", required=True)
            item.add_argument("--reference", required=True)
    item = sub.add_parser("start")
    item.add_argument("--spec", type=Path, required=True)
    item.add_argument("--harness", required=True)
    item.add_argument("--session", required=True)
    args = parser.parse_args(argv)
    try:
        if args.action == "start":
            value = start(
                json.loads(args.spec.read_text()),
                args.harness,
                args.session,
                args.state_dir,
            )
        elif args.action == "identity":
            value = identities(args.workspace, args.state_dir)
        elif args.action == "status":
            value = status(args.workspace, args.state_dir)
        elif args.action in {"pause", "resume", "cancel"}:
            value = control(
                args.workspace,
                args.action,
                getattr(args, "harness", None),
                getattr(args, "session", None),
                args.state_dir,
                loop_id=args.loop_id,
            )
        elif args.action == "record":
            value = record(
                args.workspace,
                args.task,
                args.criterion,
                args.evidence,
                args.harness,
                args.session,
                args.state_dir,
                loop_id=args.loop_id,
            )
        elif args.action == "confirm-human":
            value = confirm_human(
                args.workspace,
                args.task,
                args.criterion,
                args.quotation,
                args.reference,
                args.state_dir,
                loop_id=args.loop_id,
            )
        else:
            # CLI checks share native generic guards and baseline-aware audits.
            # A direct empty-policy coordinator would otherwise bypass them.
            import common_hook

            value = common_hook.handle_event(
                {
                    "workspace": args.workspace,
                    "harness": args.harness,
                    "session_id": args.session,
                    "kind": "stop",
                    "stop_reason": "natural",
                    "stop_control": False,
                    "manual_check": True,
                    "loop_id": args.loop_id,
                },
                state_dir=args.state_dir,
            )
            if value and (
                value.get("loop", {}).get("id") != args.loop_id
                or value.get("message") == "Stale loop ID or owner epoch rejected"
            ):
                raise LoopError("Stale loop ID rejected")
        print(json.dumps(value, indent=2))
        return 0
    except (LoopError, OSError, ValueError, subprocess.TimeoutExpired) as exc:
        print(f"agent-loop: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
