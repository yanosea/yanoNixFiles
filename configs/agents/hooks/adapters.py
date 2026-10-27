"""Native hook contracts for the installed releases; never execute tool input.

OpenCode/OpenClaw use small native plugins. Their JSON output below is the
private bridge protocol, not a claim that those products support command hooks.
"""

import json
import os
import re
import shlex
import subprocess
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path

HARNESSES = (
    "claude",
    "codex",
    "grok",
    "opencode",
    "antigravity",
    "antigravity-cli",
    "antigravity-ide",
    "kiro",
    "kiro-cli",
    "copilot",
    "openclaw",
)
STOP_CONTROL = frozenset(("claude", "codex", "grok", "copilot"))
EVENTS = {
    "pretooluse": "pre",
    "beforetoolcall": "pre",
    "executebefore": "pre",
    "pre": "pre",
    "posttooluse": "post",
    "posttoolusefailure": "post",
    "afterfileedit": "post",
    "aftershellexecution": "post",
    "aftertoolcall": "post",
    "executeafter": "post",
    "post": "post",
    "stop": "stop",
    "agentstop": "stop",
    "agentend": "stop",
    "beforeagentfinalize": "stop",
    "sessionexecutionsucceeded": "stop",
    "sessionexecutionfailed": "stop",
    "sessionexecutioninterrupted": "end",
    "sessionidle": "stop",
    "sessionstart": "start",
    "agentspawn": "start",
    "beforepromptbuild": "start",
    "start": "start",
    "precompact": "handover",
    "beforecompaction": "handover",
    "compaction": "handover",
    "handover": "handover",
    "userpromptsubmit": "prompt",
    "userpromptsubmitted": "prompt",
    "preinvocation": "prompt",
    "context": "prompt",
    "prompt": "prompt",
    "sessionend": "end",
    "interrupt": "end",
    "end": "end",
}


def command_harness(argv):
    """Inspect only program/script positions, never prompt text or later flags."""
    if not argv:
        return None
    program = Path(argv[0]).name.removeprefix(".").removesuffix("-wrapped")
    if program in {"copilot", "copilot-runtime"}:
        return "copilot"
    if program in {"claude", "grok", "codex"}:
        return program
    if program in {"node", "bun"} and len(argv) > 1:
        script = Path(argv[1])
        if script.name in {"index.js", "app.js", "cli.js"} and (
            "github-copilot-cli" in script.parts
            or ("@github" in script.parts and "copilot" in script.parts)
        ):
            return "copilot"
        if script.name == "cli.js" and "claude-code" in script.parts:
            return "claude"
    return None


def ancestor_harness():
    """Bounded auto-only discovery. No argv is logged, persisted or emitted.

    Permission failures/timeouts return unknown. Ambiguous snake-case payloads
    then use the Claude contract; explicit --harness bypasses this probe.
    """
    pid = os.getppid()
    for _ in range(8):
        if pid <= 1:
            break
        try:
            if sys.platform.startswith("linux"):
                proc = Path("/proc") / str(pid)
                argv = (
                    proc.joinpath("cmdline")
                    .read_bytes()[:8192]
                    .decode("utf8", "replace")
                    .split("\0")
                )
                found = command_harness(argv)
                if found:
                    return found
                status = proc.joinpath("status").read_text()
                match = re.search(r"^PPid:\s*(\d+)", status, re.MULTILINE)
                if not match:
                    break
                pid = int(match.group(1))
            elif sys.platform == "darwin":
                row = subprocess.run(
                    ["ps", "-p", str(pid), "-o", "ppid=", "-o", "command="],
                    capture_output=True,
                    text=True,
                    timeout=0.2,
                    check=False,
                ).stdout.strip()
                parent, _, command = row.partition(" ")
                found = command_harness(shlex.split(command))
                if found:
                    return found
                pid = int(parent)
            else:
                break
        except OSError, ValueError, subprocess.TimeoutExpired:
            break
    return None


def detect_harness(payload):
    # Native Grok markers distinguish its camelCase envelope from Copilot's.
    if (
        "workspaceRoot" in payload
        or "toolUseId" in payload
        or ("hookEventName" in payload and "sessionId" in payload)
    ):
        return "grok"
    if "toolArgs" in payload or ("sessionId" in payload and "timestamp" in payload):
        return "copilot"
    return ancestor_harness() or "claude"


def canonical_harness(harness):
    if harness not in HARNESSES:
        raise ValueError("Unsupported harness")
    if harness.startswith("antigravity-"):
        return "antigravity"
    return "kiro" if harness == "kiro-cli" else harness


def event_kind(event):
    key = re.sub(r"[^a-z]", "", event.lower())
    if key not in EVENTS:
        raise ValueError("Unsupported hook event")
    return EVENTS[key]


def _first(mapping, *keys):
    return next((mapping[key] for key in keys if mapping.get(key) is not None), None)


def _identifier(value):
    return str(value) if isinstance(value, (str, int)) and str(value) else None


def _paths(value):
    paths = []
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {
                "path",
                "file_path",
                "filePath",
                "filename",
                "TargetFile",
                "AbsolutePath",
            } and isinstance(item, str):
                paths.append(item)
            elif key in {"paths", "derivedPaths"} and isinstance(item, list):
                paths.extend(v for v in item if isinstance(v, str))
            elif isinstance(item, (list, dict)):
                paths.extend(_paths(item))
    elif isinstance(value, list):
        for item in value:
            paths.extend(_paths(item))
    return paths


def normalize(harness, event, payload):
    kind = event_kind(event)
    if not isinstance(payload, dict):
        raise ValueError("Hook payload must be a JSON object")  # noqa: TRY004 - JSON validation contract.
    harness = (
        detect_harness(payload) if harness == "auto" else canonical_harness(harness)
    )
    call = payload.get("toolCall") or {}
    if not isinstance(call, dict):
        raise ValueError("toolCall must be an object")  # noqa: TRY004 - JSON validation contract.
    tool = _first(payload, "tool_name", "toolName", "tool") or call.get("name") or ""
    args = _first(payload, "tool_input", "toolInput", "toolArgs", "params", "input")
    if args is None:
        args = call.get("args") or {}
    if isinstance(args, str):
        if str(tool).lower() == "apply_patch":
            args = {"patch": args}
        else:
            try:
                args = json.loads(args)
            except json.JSONDecodeError as exc:
                raise ValueError("tool input is not valid JSON") from exc
    if not isinstance(args, dict):
        raise ValueError("tool input must be an object")  # noqa: TRY004 - JSON validation contract.
    workspaces = payload.get("workspacePaths") or []
    workspace = _first(
        payload, "workspace", "workspaceDir", "workspaceRoot", "cwd", "working_dir"
    )
    if not workspace:
        workspace = next((v for v in workspaces if isinstance(v, str)), None)
    workspace = workspace or os.getcwd()
    if not isinstance(workspace, str):
        raise ValueError("workspace must be a path string")  # noqa: TRY004 - JSON validation contract.
    cwd = _first(args, "Cwd", "cwd", "workdir") or workspace
    if not isinstance(cwd, str):
        raise ValueError("tool working directory must be a string")  # noqa: TRY004 - JSON validation contract.
    workspace_path = Path(workspace).expanduser().resolve()
    cwd_path = Path(cwd).expanduser()
    if not cwd_path.is_absolute():
        cwd_path = workspace_path / cwd_path
    command = _first(args, "command", "cmd", "CommandLine", "script") or ""
    if isinstance(command, list):
        if not all(isinstance(item, str) for item in command):
            raise ValueError("command argv must contain strings")
        command = shlex.join(command)
    if not isinstance(command, str):
        raise ValueError("command must be a string or argv")  # noqa: TRY004 - JSON validation contract.
    patch = _first(args, "patch", "patch_text", "patchText") or ""
    if str(tool).lower() == "apply_patch" and not patch:
        patch = args.get("input") or command
    if not isinstance(patch, str):
        raise ValueError("patch must be a string")  # noqa: TRY004 - JSON validation contract.
    paths = _paths(args) + _paths({"derivedPaths": payload.get("derivedPaths", [])})
    paths.extend(
        re.findall(r"^\*\*\* (?:Add|Update|Delete) File: (.+)$", patch, re.MULTILINE)
    )
    paths.extend(re.findall(r"^\*\*\* Move to: (.+)$", patch, re.MULTILINE))
    result = {
        "kind": kind,
        "harness": harness,
        "native_event": event,
        "workspace": str(workspace_path),
        "cwd": str(cwd_path.resolve()),
        "session_id": _identifier(
            _first(
                payload,
                "session_id",
                "sessionId",
                "sessionID",
                "sessionKey",
                "conversationId",
            )
        ),
        # A tool call/message id is not a turn id. Keep missing turns unknown.
        "turn_id": _identifier(
            _first(payload, "turn_id", "turnId", "prompt_id", "promptId", "runId")
        ),
        "tool_call_id": _identifier(
            _first(
                payload, "tool_call_id", "toolCallId", "tool_use_id", "toolUseId", "id"
            )
        ),
        "tool_name": str(tool),
        "tool_input": args,
        "command": command,
        "paths": list(dict.fromkeys(paths)),
        "patch": patch,
        "tool_result": _first(
            payload,
            "tool_response",
            "tool_output",
            "toolOutput",
            "toolResult",
            "result",
        ),
        "stop_control": harness in STOP_CONTROL,
        "stop_hook_active": _first(payload, "stop_hook_active", "stopHookActive")
        is True,
    }
    for target, keys in {
        "transcript_path": ("transcript_path", "transcriptPath"),
        "prompt": ("prompt", "message", "initialPrompt", "initial_prompt"),
        "prompt_event_id": ("prompt_event_id", "promptEventId", "currentUserMessageId"),
    }.items():
        value = _first(payload, *keys)
        if isinstance(value, str):
            result[target] = value
    # Copilot provides a prompt admission timestamp, not a turn id. Keep it
    # stable across the native/global and Claude-compatible/project callbacks;
    # timestamps on later tool/stop events must never become new turn ids.
    if harness == "copilot" and kind == "prompt" and "prompt_event_id" not in result:
        timestamp = payload.get("timestamp")
        if isinstance(timestamp, str):
            try:
                instant = datetime.fromisoformat(timestamp)
                if instant.tzinfo is not None:
                    timestamp = (
                        instant - datetime(1970, 1, 1, tzinfo=UTC)
                    ) // timedelta(milliseconds=1)
            except ValueError:
                pass
        if (
            isinstance(timestamp, (str, int))
            and not isinstance(timestamp, bool)
            and str(timestamp)
        ):
            result["prompt_event_id"] = "copilot-timestamp:" + str(timestamp)
    result["context_only"] = (
        payload.get("context_only") is True
        or harness == "antigravity"
        and event == "PreInvocation"
    )
    if result["context_only"] and kind == "start":
        result["kind"] = "prompt"
    result["observation_only"] = payload.get("observation_only") is True or event in {
        "agent_end",
        "session.idle",
    }
    # The asynchronous bridges supply host-classified lifecycle metadata.
    for key in ("stop_reason", "origin", "loop_id", "request_id", "stop_event_id"):
        if isinstance(payload.get(key), str):
            result[key] = payload[key]
    if isinstance(payload.get("stop_event_seq"), int) and not isinstance(
        payload["stop_event_seq"], bool
    ):
        result["stop_event_seq"] = payload["stop_event_seq"]
    if isinstance(payload.get("owner_epoch"), int) and not isinstance(
        payload["owner_epoch"], bool
    ):
        result["owner_epoch"] = payload["owner_epoch"]
    if (
        isinstance(payload.get("host_pid"), int)
        and not isinstance(payload["host_pid"], bool)
        and payload["host_pid"] > 0
    ):
        result["host_pid"] = payload["host_pid"]
    if harness == "antigravity" and kind == "stop":
        reason = payload.get("terminationReason")
        natural = (
            reason in {"model_stop", "NO_TOOL_CALL"}
            and payload.get("fullyIdle") is True
            and not payload.get("error")
        )
        result["stop_reason"] = (
            "natural"
            if natural
            else "error"
            if reason == "error" or payload.get("error")
            else "abort"
            if reason and reason not in {"model_stop", "NO_TOOL_CALL"}
            else "unknown"
        )
        result["stop_control"] = natural
    elif harness == "opencode":
        result["stop_reason"] = result.get("stop_reason", "unknown")
        result["stop_control"] = (
            event == "session.execution.succeeded"
            and result["stop_reason"] == "natural"
        )
    elif harness == "openclaw":
        result["origin"] = result.get("origin", "unknown")
        result["stop_control"] = (
            event == "before_agent_finalize" and result["origin"] == "interactive"
        )
    if event in {"Interrupt", "SessionEnd", "session.execution.interrupted"}:
        result["stop_reason"] = "abort"
    if isinstance(payload.get("handover_text"), str):
        result["handover_text"] = payload["handover_text"]
    return result


def emit(harness, event, result):
    """Return (stdout JSON/text, exit code); exit-2 text belongs on stderr."""
    harness = canonical_harness(harness)
    kind = event_kind(event)
    action = result.get("action", "allow")
    message = result.get("message") or ""
    if not isinstance(message, str):
        message = str(message)
    if harness == "kiro":
        return (
            (message, 2) if kind == "pre" and action == "deny" else (message or None, 0)
        )
    if harness == "openclaw":
        if kind == "pre":
            return (
                {"block": True, "blockReason": message} if action == "deny" else {}
            ), 0
        output = {"context": message, "report": message}
        if (
            event == "before_agent_finalize"
            and action == "continue"
            and result.get("loop", {}).get("state") == "running"
        ):
            output.update(action="revise", reason=message)
        return output, 0
    if harness == "opencode":
        output = {
            "decision": "deny" if kind == "pre" and action == "deny" else "allow",
            "context": message,
            "reason": message,
        }
        if "loop" in result:
            output.update(action=action, loop=result["loop"])
        return output, 0
    if kind == "stop" and action == "continue" and harness in STOP_CONTROL:
        return {"decision": "block", "reason": message}, 0
    if harness == "antigravity":
        if (
            kind == "stop"
            and action == "continue"
            and result.get("loop", {}).get("state") == "running"
        ):
            return {"decision": "continue", "reason": message}, 0
        if kind == "pre":
            return {
                "decision": "deny" if action == "deny" else "allow",
                **({"reason": message} if message else {}),
            }, 0
        if event in {"SessionStart", "PreInvocation"} and message:
            return {"injectSteps": [{"ephemeralMessage": message}]}, 0
        return {}, 0
    if harness == "copilot":
        if kind == "pre" and action == "deny":
            return {
                "permissionDecision": "deny",
                "permissionDecisionReason": message,
            }, 0
        return (
            {"additionalContext": message}
            if message and kind in {"post", "start"}
            else {}
        ), 0
    if kind == "pre":
        specific = {"hookEventName": "PreToolUse"}
        if action == "deny":
            specific.update(permissionDecision="deny", permissionDecisionReason=message)
        elif message:
            specific["additionalContext"] = message
        return ({"hookSpecificOutput": specific} if len(specific) > 1 else {}), 0
    if harness == "grok" and kind not in {"post", "stop"}:
        return {}, 0  # Passive Grok stdout is discarded by the native runtime.
    if message and kind in {"post", "prompt", "start"}:
        native = {
            "post": "PostToolUse",
            "prompt": "UserPromptSubmit",
            "start": "SessionStart",
        }[kind]
        return {
            "hookSpecificOutput": {
                "hookEventName": native,
                "additionalContext": message,
            }
        }, 0
    return ({"systemMessage": message} if message else {}), 0
