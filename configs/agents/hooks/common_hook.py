"""Shared, standard-library hook policy and content checks.

Known operations are classified; this is not a general shell sandbox. No tool
payload is executed. Only explicitly configured project check argv is run.
Adapters own native schemas and capabilities; this module owns shared state.
"""

import argparse
import contextlib
import fcntl
import hashlib
import importlib.util
import json
import os
import re
import select
import shlex
import signal
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path

# File-based loading keeps trusted project wrappers using compile/exec compatible
# without assuming hooks are installed on sys.path.
_loop_spec = importlib.util.spec_from_file_location(
    "agent_loop_shared", Path(__file__).with_name("agent_loop.py")
)
_loop_module = importlib.util.module_from_spec(_loop_spec)
_loop_spec.loader.exec_module(_loop_module)
LoopError = _loop_module.LoopError
register_provider = _loop_module.register_provider
prepare_provider = _loop_module.prepare_provider
submit_provider = _loop_module.submit_provider
refresh_provider_content = _loop_module.refresh_provider_content
validate_delivery = _loop_module.validate_delivery
claim_delivery = _loop_module.claim_delivery
finish_delivery = _loop_module.finish_delivery


DEFAULT_POLICY = {
    "deny": {
        "git_reset_hard": True,
        "git_clean_force": True,
        "git_force_push": True,
        "git_metadata_write": True,
    },
    "checks": {"whitespace": True, "conflict_markers": True},
    "research_reminder": True,
    "project_commands": [],
    "overall_timeout": 90,
}
REMINDER = (
    "Before answering, designing, implementing or changing configuration, search "
    "the web for current information and best practices. Read official source "
    "bodies, including the feature's guide pages, and trace config keys to the "
    "code that reads them. Record the source URLs, checked versions and reasons "
    "in the existing plan or handover, and pass this research to any delegate. "
    "Search summaries alone are not evidence. This reminder does not prove that "
    "research happened."
)
# openclaw runs have no plan, handover or delegate, so they get only the research part
OPENCLAW_REMINDER = (
    "Before answering with facts that change, such as versions, prices or tool "
    "behaviour, search the web and read the official source bodies. Search "
    "summaries alone are not evidence."
)
MAX_BYTES = 32 * 1024 * 1024
MAX_FILES = 5000
MAX_INPUT = 4 * 1024 * 1024
WRITE_COMMANDS = {
    "rm",
    "mv",
    "cp",
    "install",
    "touch",
    "mkdir",
    "rmdir",
    "tee",
    "truncate",
    "chmod",
    "chown",
    "patch",
    "rsync",
}
PATH_KEYS = {"path", "file_path", "filePath", "filename", "TargetFile", "AbsolutePath"}
READ_TOOLS = {
    "read",
    "readfile",
    "read_file",
    "view_file",
    "get_file",
    "cat",
    "glob",
    "grep",
    "search",
    "list_files",
    "list_directory",
    "ls",
    "tree",
}
READ_GIT = {
    "status",
    "diff",
    "log",
    "show",
    "rev-parse",
    "ls-files",
    "ls-tree",
    "cat-file",
    "for-each-ref",
    "check-ignore",
    "check-attr",
    "help",
    "version",
    "blame",
    "grep",
}


class HookError(Exception):
    """An audit cannot establish a complete, current result."""


def merge_policy(override=None):
    policy = json.loads(json.dumps(DEFAULT_POLICY))
    if override is None:
        return policy
    if not isinstance(override, dict):
        raise HookError("Policy must be a JSON object")
    for section in ("deny", "checks"):
        values = override.get(section, {})
        if not isinstance(values, dict):
            raise HookError(f"Policy {section} must be an object")
        for key, value in values.items():
            if key not in policy[section] or not isinstance(value, bool):
                raise HookError(f"Invalid policy field: {section}.{key}")
            policy[section][key] = value
    for key in ("research_reminder", "project_commands", "overall_timeout"):
        if key in override:
            policy[key] = override[key]
    if not isinstance(policy["research_reminder"], bool):
        raise HookError("research_reminder must be boolean")
    timeout = policy["overall_timeout"]
    if (
        isinstance(timeout, bool)
        or not isinstance(timeout, (int, float))
        or not 0 < timeout <= 600
    ):
        raise HookError("overall_timeout must be between 0 and 600 seconds")
    if not isinstance(policy["project_commands"], list):
        raise HookError("project_commands must be a list of explicit argv entries")
    for entry in policy["project_commands"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("argv"), list):
            raise HookError("Project checks require an explicit argv list")
        if not entry["argv"] or not all(
            isinstance(v, str) and v and "\0" not in v for v in entry["argv"]
        ):
            raise HookError("Project check argv must contain nonempty strings")
        argv = unwrap(entry["argv"])
        if any(arg in {"--fix", "--fix-only", "--write", "--auto-fix"} for arg in argv):
            raise HookError("Project checks cannot request auto-fix")
        if argv and Path(argv[0]).name == "git":
            subcommand = git_subcommand(argv[1:])
            if subcommand not in READ_GIT:
                raise HookError(
                    "Project checks cannot modify, stage or commit Git content"
                )
        timeout = entry.get("timeout", 20)
        if (
            isinstance(timeout, bool)
            or not isinstance(timeout, (int, float))
            or not 0 < timeout <= 600
        ):
            raise HookError("Invalid project check timeout")
    return policy


def load_policy(path=None):
    explicit = path is not None or bool(os.environ.get("AGENT_HOOK_POLICY"))
    selected = path or os.environ.get("AGENT_HOOK_POLICY")
    if not selected:
        selected = (
            Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
            / "agents/hooks-policy.json"
        )
    path = Path(selected).expanduser()
    if not path.exists():
        if explicit:
            raise HookError(f"Policy does not exist: {path}")
        return merge_policy()
    try:
        policy = merge_policy(json.loads(path.read_text()))
        if policy["project_commands"]:
            raise HookError(
                "Global policy cannot define project_commands; supply reviewed checks explicitly from a local hook"
            )
        return policy
    except (OSError, ValueError) as exc:
        raise HookError(f"Cannot read policy: {exc}") from exc


def run(argv, cwd, timeout=5, deadline=None):
    if deadline is not None:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise HookError("Overall hook timeout")
        timeout = min(timeout, remaining)
    try:
        process = subprocess.Popen(
            argv,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
    except OSError as exc:
        raise HookError(f"Cannot run {Path(argv[0]).name}: {exc}") from exc
    try:
        output, error = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        with contextlib.suppress(ProcessLookupError):
            os.killpg(process.pid, signal.SIGKILL)
        process.communicate()
        raise HookError(f"Check timeout: {Path(argv[0]).name}")
    if len(output) > MAX_BYTES or len(error) > MAX_BYTES:
        raise HookError("Command output exceeds audit size limit")
    return process.returncode, output, error


def git(argv, cwd, deadline=None):
    # Avoid external diff/textconv and optional index writes in read-only checks.
    base = [
        "git",
        "--no-optional-locks",
        "-c",
        "core.quotePath=false",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.hooksPath=/dev/null",
    ]
    if "diff" in argv:
        # Even --no-ext-diff/--no-textconv still allows configured clean filters.
        # Disable every discovered filter driver without modifying repo config.
        code, out, _ = run(
            base
            + [
                "config",
                "--null",
                "--get-regexp",
                r"^filter\..*\.(clean|smudge|process|required)$",
            ],
            cwd,
            deadline=deadline,
        )
        if code not in {0, 1}:
            raise HookError("Cannot inspect Git filter configuration")
        drivers = {
            os.fsdecode(entry.split(b"\n", 1)[0]).rsplit(".", 1)[0]
            for entry in out.split(b"\0")
            if entry
        }
        for driver in sorted(drivers):
            for key, value in (
                ("clean", ""),
                ("smudge", ""),
                ("process", ""),
                ("required", "false"),
            ):
                base.extend(["-c", f"{driver}.{key}={value}"])
    return run([*base, *argv], cwd, deadline=deadline)


def repository(workspace, deadline=None):
    code, out, error = git(["rev-parse", "--show-toplevel"], workspace, deadline)
    if code != 0:
        marker = False
        for parent in (workspace, *workspace.parents):
            candidate = parent / ".git"
            # Ignore empty ancestor placeholders (including sandbox /tmp/.git).
            # A marker in the requested workspace or actual ancestor Git data
            # makes a failed rev-parse an audit error, never a successful skip.
            if (
                candidate.is_symlink()
                or candidate.is_file()
                or (
                    candidate.is_dir()
                    and (
                        parent == workspace
                        or any(
                            (candidate / entry).exists()
                            for entry in ("HEAD", "config", "objects")
                        )
                    )
                )
            ):
                marker = True
                break
        if marker or b"not a git repository" not in error.lower():
            raise HookError(
                "Cannot inspect Git repository: "
                + error.decode("utf-8", errors="replace").strip()
            )
        return None, {workspace / ".git"}
    root = Path(os.fsdecode(out).strip()).resolve()
    metadata = {root / ".git"}
    for option in ("--absolute-git-dir", "--git-common-dir"):
        code, out, _ = git(["rev-parse", option], workspace, deadline)
        if code != 0:
            raise HookError("Cannot resolve Git metadata directories")
        path = Path(os.fsdecode(out).strip())
        metadata.add((path if path.is_absolute() else workspace / path).resolve())
    return root, metadata


def path_of(value, cwd):
    path = Path(os.path.expandvars(os.path.expanduser(value)))
    return (path if path.is_absolute() else cwd / path).resolve()


def is_metadata(value, cwd, metadata):
    try:
        target = path_of(value, cwd)
        return (
            any(target == root or root in target.parents for root in metadata)
            or ".git" in target.parts
        )
    except (OSError, ValueError, TypeError):
        return False


def native_paths(value):
    paths = []
    if isinstance(value, dict):
        for key, item in value.items():
            if key in PATH_KEYS and isinstance(item, str):
                paths.append(item)
            elif key == "paths" and isinstance(item, list):
                paths.extend(p for p in item if isinstance(p, str))
            elif key in {"patch", "patch_text", "input", "command"} and isinstance(
                item, str
            ):
                paths.extend(
                    re.findall(
                        r"^\*\*\* (?:Add|Update|Delete) File: (.+)$", item, re.MULTILINE
                    )
                )
                paths.extend(re.findall(r"^\*\*\* Move to: (.+)$", item, re.MULTILINE))
            elif isinstance(item, (list, dict)):
                paths.extend(native_paths(item))
    elif isinstance(value, list):
        for item in value:
            paths.extend(native_paths(item))
    return paths


def segments(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|<>()\n")
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    lexer.commenters = "#"
    result, current = [], []
    for token in lexer:
        if token in {";", "&&", "||", "|", "&", "\n", "(", ")"}:
            if current:
                result.append(current)
                current = []
        else:
            current.append(token)
    if current:
        result.append(current)
    return result


def unwrap(tokens):
    tokens = list(tokens)
    while tokens:
        name = Path(tokens[0]).name
        if re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", tokens[0]):
            tokens.pop(0)
        elif name in {"env", "command", "sudo"}:
            tokens.pop(0)
            while tokens and tokens[0].startswith("-"):
                flag = tokens.pop(0)
                if (
                    flag in {"-u", "--unset", "-C", "--chdir", "--user", "-g"}
                    and tokens
                ):
                    tokens.pop(0)
        else:
            break
    return tokens


def git_subcommand(args):
    index = 0
    while index < len(args) and args[index].startswith("-"):
        flag = args[index]
        index += 1
        if flag in {
            "-C",
            "-c",
            "--git-dir",
            "--work-tree",
            "--namespace",
            "--config-env",
        }:
            index += 1
    return args[index] if index < len(args) else ""


def command_policy(command, cwd, metadata, policy, depth=0):
    if not command:
        return ""
    if not isinstance(command, str) or depth > 5:
        return "Cannot classify malformed or deeply nested shell input"
    try:
        commands = segments(command)
    except ValueError:
        return "Cannot classify malformed shell input"
    deny = policy["deny"]
    for raw in commands:
        tokens = unwrap(raw)
        if not tokens:
            continue
        name, args = Path(tokens[0]).name, tokens[1:]
        if name == "cd" and args:
            cwd = path_of(args[0], cwd)
            continue
        if deny["git_metadata_write"]:
            for i, token in enumerate(tokens[:-1]):
                if re.fullmatch(r"[0-9]*(?:>|>>|<>|>\|)", token) and is_metadata(
                    tokens[i + 1], cwd, metadata
                ):
                    return "Direct Git metadata writes are prohibited"
            operands = [arg for arg in args if not arg.startswith("-")]
            if name in {"cp", "install"}:
                # Their sources may legitimately be read from Git metadata.
                operands = operands[-1:]
                for index, arg in enumerate(args[:-1]):
                    if arg in {"-t", "--target-directory"}:
                        operands.append(args[index + 1])
            if name in WRITE_COMMANDS and any(
                is_metadata(arg, cwd, metadata) for arg in operands
            ):
                return "Direct Git metadata writes are prohibited"
        if name in {"bash", "sh", "zsh", "dash"}:
            for i, arg in enumerate(args[:-1]):
                if (
                    arg == "--command"
                    or arg.startswith("-")
                    and not arg.startswith("--")
                    and "c" in arg[1:]
                ):
                    reason = command_policy(
                        args[i + 1], cwd, metadata, policy, depth + 1
                    )
                    if reason:
                        return reason
        if name != "git":
            continue
        index = 0
        while index < len(args) and args[index].startswith("-"):
            flag = args[index]
            index += 1
            if flag in {
                "-C",
                "-c",
                "--git-dir",
                "--work-tree",
                "--namespace",
                "--config-env",
            }:
                index += 1
        if index >= len(args):
            continue
        subcommand, options = args[index], args[index + 1 :]
        if subcommand == "reset" and "--hard" in options and deny["git_reset_hard"]:
            return "git reset --hard is prohibited by shared policy"
        short = "".join(
            arg[1:]
            for arg in options
            if arg.startswith("-") and not arg.startswith("--")
        )
        if subcommand == "clean" and deny["git_clean_force"]:
            force = "f" in short or "--force" in options
            dry_run = "n" in short or "--dry-run" in options
            if force and not dry_run:
                return "Deleting git clean -f is prohibited by shared policy"
        if subcommand == "push" and deny["git_force_push"]:
            force = (
                "f" in short
                or "--force" in options
                or any(arg.startswith("+") for arg in options)
            )
            if force and not ("n" in short or "--dry-run" in options):
                return "Unconditional force push is prohibited; use --force-with-lease"
    return ""


def issue_key(issue):
    return json.dumps([issue["file"], issue["kind"], issue["text"]], ensure_ascii=True)


def line_issues(path, lines, source, checks):
    issues = []
    for number, text in lines:
        if checks["whitespace"] and (
            re.search(r"[ \t]+$", text) or re.match(r"^ * +\t", text)
        ):
            issues.append(
                {
                    "file": path,
                    "line": number,
                    "kind": "whitespace",
                    "text": text,
                    "source": source,
                }
            )
        if checks["conflict_markers"] and re.match(
            r"^(?:<{7}(?: |$)|={7}$|>{7}(?: |$)|\|{7}(?: |$))", text
        ):
            issues.append(
                {
                    "file": path,
                    "line": number,
                    "kind": "conflict_marker",
                    "text": text,
                    "source": source,
                }
            )
    return issues


def added_lines(patch):
    number = None
    for line in patch.decode("utf-8", errors="replace").splitlines():
        match = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if match:
            number = int(match.group(1))
        elif number is not None and line.startswith("+"):
            yield number, line[1:]
            number += 1
        elif number is not None and line.startswith(" "):
            number += 1


def snapshot(root, policy, deadline=None):
    if root is None:
        return {"fingerprint": "non-git", "issues": [], "dirty": False}
    digest = hashlib.sha256()
    code, head, _ = git(["rev-parse", "--verify", "HEAD"], root, deadline)
    if code == 0:
        digest.update(head)
    elif code != 128:
        raise HookError("Cannot fingerprint repository HEAD")
    issues = []
    layers = []
    names = set()
    untracked = set()
    for cached in (False, True):
        options = ["--cached"] if cached else []
        code, out, _ = git(
            [
                "diff",
                "--no-ext-diff",
                "--no-textconv",
                "--no-renames",
                "--binary",
                *options,
            ],
            root,
            deadline,
        )
        if code != 0:
            raise HookError("Cannot fingerprint Git changes")
        digest.update(b"index" if cached else b"working")
        digest.update(out)
        code, out, _ = git(
            [
                "diff",
                "--no-ext-diff",
                "--no-textconv",
                "--no-renames",
                "--name-only",
                "-z",
                *options,
            ],
            root,
            deadline,
        )
        if code != 0:
            raise HookError("Cannot list Git changes")
        layer = {os.fsdecode(name) for name in out.split(b"\0") if name}
        names.update(layer)
        layers.append((cached, layer))
    code, out, _ = git(
        ["ls-files", "--others", "--exclude-standard", "-z"], root, deadline
    )
    if code != 0:
        raise HookError("Cannot list untracked files")
    untracked.update(os.fsdecode(name) for name in out.split(b"\0") if name)
    names.update(untracked)
    if len(names) > MAX_FILES:
        raise HookError("Changed file count exceeds audit limit")
    total = 0
    for name in sorted(untracked):
        path = root / name
        if path.is_symlink():
            data = os.fsencode(os.readlink(path))
        elif path.is_file():
            if path.stat().st_size > MAX_BYTES:
                raise HookError(f"Untracked file exceeds audit limit: {name}")
            data = path.read_bytes()
        else:
            raise HookError(f"Cannot inspect untracked path: {name}")
        total += len(data)
        if total > MAX_BYTES:
            raise HookError("Untracked content exceeds audit size limit")
        digest.update(os.fsencode(name) + b"\0" + data + b"\0")
        if b"\0" not in data and not path.is_symlink():
            text = data.decode("utf-8", errors="replace")
            issues.extend(
                line_issues(
                    name, enumerate(text.splitlines(), 1), "untracked", policy["checks"]
                )
            )
            if policy["checks"]["whitespace"] and text.endswith("\n\n"):
                issues.append(
                    {
                        "file": name,
                        "line": len(text.splitlines()),
                        "kind": "whitespace",
                        "text": "blank line at EOF",
                        "source": "untracked",
                    }
                )
    # File-scoped patches avoid parsing quoted filenames and cover the index
    # even when the working file has subsequently been corrected or deleted.
    combined = {}
    for cached, layer in layers:
        layer_issues = []
        for name in sorted(layer):
            options = ["--cached"] if cached else []
            code, out, _ = git(
                [
                    "diff",
                    "--no-ext-diff",
                    "--no-textconv",
                    "--no-renames",
                    "--no-color",
                    "--unified=0",
                    *options,
                    "--",
                    name,
                ],
                root,
                deadline,
            )
            if code != 0:
                raise HookError(f"Cannot inspect changed file: {name}")
            layer_issues.extend(
                line_issues(
                    name,
                    added_lines(out),
                    "staged" if cached else "unstaged",
                    policy["checks"],
                )
            )
            if policy["checks"]["whitespace"]:
                code, out, _ = git(
                    [
                        "-c",
                        "core.whitespace=trailing-space,space-before-tab,blank-at-eof",
                        "diff",
                        "--no-ext-diff",
                        "--no-textconv",
                        "--check",
                        *options,
                        "--",
                        name,
                    ],
                    root,
                    deadline,
                )
                if code not in {0, 2}:
                    raise HookError(f"Cannot inspect whitespace: {name}")
                for text in out.decode("utf-8", errors="replace").splitlines():
                    match = re.match(r".*:(\d+): new blank line at EOF\.$", text)
                    if match:
                        layer_issues.append(
                            {
                                "file": name,
                                "line": int(match.group(1)),
                                "kind": "whitespace",
                                "text": "blank line at EOF",
                                "source": "staged" if cached else "unstaged",
                            }
                        )
        counts = Counter(issue_key(issue) for issue in layer_issues)
        for key, count in counts.items():
            existing = combined.setdefault(key, [])
            candidates = [issue for issue in layer_issues if issue_key(issue) == key]
            if len(existing) < count:
                combined[key] = candidates
    issues.extend(issue for values in combined.values() for issue in values)
    return {"fingerprint": digest.hexdigest(), "issues": issues, "dirty": bool(names)}


def new_issues(current, baseline):
    prior = Counter(issue_key(issue) for issue in baseline)
    result = []
    for issue in current:
        key = issue_key(issue)
        if prior[key]:
            prior[key] -= 1
        else:
            result.append(issue)
    return result


def state_location(workspace, harness, session, state_dir):
    base = state_dir or os.environ.get("AGENT_HOOK_STATE_DIR")
    if base is None:
        base = (
            Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
            / "agents/hooks"
        )
    identity = json.dumps([str(workspace), harness, session]).encode()
    return Path(base).expanduser() / hashlib.sha256(identity).hexdigest()


@contextlib.contextmanager
def locked_state(location, deadline):
    location.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (location / "lock").open("a+") as lock:
        while True:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise HookError("Timeout waiting for session audit lock")
                time.sleep(0.025)
        try:
            path = location / "state.json"
            try:
                state = json.loads(path.read_text()) if path.exists() else {}
            except (OSError, ValueError) as exc:
                raise HookError(f"Cannot read session state: {exc}") from exc
            yield state
            atomic_write(path, json.dumps(state, ensure_ascii=True))
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def atomic_write(path, text):
    descriptor, name = tempfile.mkstemp(prefix=".agent-hook-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(name)


def handover(workspace, text=None):
    path = workspace / "HANDOVER.md"
    if text is not None:
        if (
            not isinstance(text, str)
            or not text.strip()
            or text.startswith("# Auto-generated note")
        ):
            raise HookError("Handover text must contain actual session context")
        if path.is_symlink():
            raise HookError("Refusing to replace a symlinked HANDOVER.md")
        atomic_write(path, text)
    if not path.exists():
        return ""
    if path.stat().st_size > MAX_BYTES:
        raise HookError("HANDOVER.md exceeds size limit")
    return path.read_text(errors="replace")


def reminder(event, policy):
    """Return the research reminder for this event; openclaw gets it only interactively."""
    if not policy["research_reminder"]:
        return ""
    if event.get("harness") == "openclaw":
        return OPENCLAW_REMINDER if event.get("origin") == "interactive" else ""
    return REMINDER


def result(action="allow", message="", issues=None, pending=False):
    return {
        "action": action,
        "message": message,
        "issues": issues or [],
        "pending": pending,
    }


def audit(event, policy, state, root, deadline):
    kind = event["kind"]
    current = snapshot(root, policy, deadline)
    if "baseline" not in state:
        state["baseline"] = current["issues"] if kind in {"start", "pre"} else []
    baseline = state["baseline"]
    state["seen"] = current["fingerprint"]
    issues = new_issues(current["issues"], baseline)
    if kind in {"start", "pre"}:
        state["pending"] = (
            state.get("checked") != current["fingerprint"] and current["dirty"]
        )
        return result(pending=state["pending"])
    if kind == "post":
        after = snapshot(root, policy, deadline)
        changed_during_check = after["fingerprint"] != current["fingerprint"]
        state["common_checked"] = current["fingerprint"]
        state["common_issues"] = issues
        state["pending"] = (
            changed_during_check
            or bool(policy["project_commands"])
            and current["dirty"]
        )
        if not policy["project_commands"] and not changed_during_check:
            state["checked"] = current["fingerprint"]
        return result(
            "notify" if issues else "allow",
            issue_message(issues),
            issues,
            state["pending"],
        )
    if kind != "stop":
        return result()
    policy_hash = hashlib.sha256(
        json.dumps(policy, sort_keys=True).encode()
    ).hexdigest()
    cached = (
        state.get("checked") == current["fingerprint"]
        and state.get("check_policy") == policy_hash
    )
    check_issues = state.get("check_issues", []) if cached else []
    pending = False
    if not cached and current["dirty"]:
        for entry in policy["project_commands"]:
            argv = entry["argv"]
            try:
                code, out, err = run(
                    argv,
                    root or Path(event["workspace"]),
                    entry.get("timeout", 20),
                    deadline,
                )
                if code:
                    check_issues.append(
                        {
                            "kind": "project_check",
                            "message": f"Check failed ({code}): {shlex.join(argv)}\n"
                            + (out + err).decode("utf-8", errors="replace")[-4000:],
                        }
                    )
            except HookError as exc:
                check_issues.append({"kind": "project_check", "message": str(exc)})
                pending = True
    after = snapshot(root, policy, deadline)
    if after["fingerprint"] != current["fingerprint"]:
        pending = True
        issues = new_issues(after["issues"], baseline)
        check_issues.append(
            {
                "kind": "pending",
                "message": "Files changed during checks; current content remains unchecked",
            }
        )
    if not pending:
        state["checked"] = current["fingerprint"]
        state["check_policy"] = policy_hash
        state["check_issues"] = check_issues
    else:
        state.pop("checked", None)
    state["pending"] = pending
    issues.extend(check_issues)
    for item in event.get("external_issues", []) or []:
        issues.append(
            item
            if isinstance(item, dict)
            else {"kind": "external", "message": str(item)}
        )
    return stop_result(event, state, issues, pending)


def issue_message(issues):
    lines = []
    for issue in issues[:20]:
        if "file" in issue:
            lines.append(
                f"{issue['file']}:{issue.get('line', '?')}: {issue['kind']}: {issue.get('text', '')}"
            )
        else:
            lines.append(str(issue.get("message", issue)))
    if len(issues) > 20:
        lines.append(f"{len(issues) - 20} more issue(s)")
    return "\n".join(lines)


def stop_result(event, state, issues, pending):
    turn = event.get("turn_id")
    key = (
        str(turn)
        if isinstance(turn, (str, int)) and str(turn)
        else state.get("current_turn", "unknown-turn")
    )
    corrections = state.setdefault("corrections", [])
    if event.get("stop_hook_active") and key not in corrections:
        corrections.append(key)
    if not issues and not pending:
        return result()
    message = issue_message(issues) or "Current changes remain unchecked"
    if event.get("stop_hook_active"):
        return result("notify", message, issues, pending)
    if event.get("stop_control") and key not in corrections:
        corrections.append(key)
        return result(
            "continue",
            "Fix the reported issues once, then rerun the relevant checks.\n" + message,
            issues,
            pending,
        )
    return result("notify", message, issues, pending)


def handle_event(event, policy=None, state_dir=None):
    """Process normalized events. External project gates share the correction budget.

    Callers may pass external_issues to a stop event, and explicit project_commands
    through policy. Do not emit an independent native stop block in the caller.
    """
    kind = event.get("kind", "") if isinstance(event, dict) else ""
    try:
        if not isinstance(event, dict):
            raise HookError("Hook event must be an object")
        policy = merge_policy(policy) if policy is not None else load_policy()
        workspace = Path(event.get("workspace") or os.getcwd()).expanduser().resolve()
        if not workspace.is_dir():
            raise HookError("Workspace does not exist")
        deadline = time.monotonic() + policy["overall_timeout"]
        root, metadata = repository(workspace, deadline)
        tool_cwd = path_of(
            event.get("cwd") or event.get("tool_cwd") or str(workspace), workspace
        )
        if kind == "pre":
            tool_name = str(event.get("tool_name", "")).lower()
            if (
                policy["deny"]["git_metadata_write"]
                and tool_name not in READ_TOOLS
                and any(
                    is_metadata(path, tool_cwd, metadata)
                    for path in native_paths(event)
                )
            ):
                return result("deny", "Direct Git metadata writes are prohibited")
            reason = command_policy(event.get("command"), tool_cwd, metadata, policy)
            if reason:
                return result("deny", reason)
        if kind in {"handover", "save_handover"}:
            handover(workspace, event.get("handover_text"))
            return result()
        # Explicit loops use a workspace coordinator outside the normal audit
        # lock. Existing basic Git guards above remain in force. No hook starts
        # a loop; native identities are only observed for a later explicit CLI.
        if kind in {"start", "prompt", "pre", "post", "stop", "end"}:
            observed = _loop_module.observe_session(
                dict(event, workspace=str(workspace)), state_dir
            )
            active = _loop_module.status(workspace, state_dir) if observed else {}
            if (
                active
                and active.get("state") not in _loop_module.TERMINAL
                and not event.get("observation_only")
            ):
                loop_event = dict(event, workspace=str(workspace))
                if kind == "stop":
                    transcript_path = event.get("transcript_path")
                    assistant_message = event.get("last_assistant_message")
                    transcript = (
                        path_of(transcript_path, workspace)
                        if isinstance(transcript_path, str)
                        else None
                    )
                    if (
                        transcript is not None
                        and transcript.is_file()
                        and transcript.stat().st_size <= MAX_INPUT
                    ):
                        for raw_line in reversed(
                            transcript.read_text(errors="replace").splitlines()
                        ):
                            try:
                                item = json.loads(raw_line)
                            except ValueError:
                                continue
                            if not isinstance(item, dict):
                                continue
                            message = item.get("message", {})
                            if item.get("type") == "assistant" and isinstance(
                                message, dict
                            ):
                                assistant_id = item.get("uuid") or message.get("id")
                                if isinstance(assistant_id, str) and assistant_id:
                                    loop_event["loop_stop_id"] = assistant_id
                                    break
                    elif isinstance(assistant_message, str) and assistant_message:
                        loop_event["loop_stop_id"] = hashlib.sha256(
                            assistant_message.encode()
                        ).hexdigest()
                if kind == "stop" and root is not None:
                    current = snapshot(root, policy, deadline)
                    location = state_location(
                        root,
                        event.get("harness", ""),
                        event.get("session_id", ""),
                        state_dir,
                    )
                    with locked_state(
                        location, min(deadline, time.monotonic() + 2)
                    ) as basic:
                        basic.setdefault("baseline", [])
                        loop_event["common_issues"] = new_issues(
                            current["issues"], basic["baseline"]
                        )
                loop_value = _loop_module.handle_loop(loop_event, policy, state_dir)
                if loop_value is not None:
                    return loop_value
        if kind == "prompt":
            session, harness = event.get("session_id"), event.get("harness")
            identity = event.get("turn_id") or event.get("prompt_event_id")
            if identity is None and isinstance(event.get("transcript_path"), str):
                transcript = path_of(event["transcript_path"], workspace)
                if transcript.is_file() and transcript.stat().st_size <= MAX_INPUT:
                    identity = hashlib.sha256(
                        transcript.read_bytes() + str(event.get("prompt", "")).encode()
                    ).hexdigest()
            deliver_reminder = True
            if (
                isinstance(session, str)
                and session.strip()
                and isinstance(harness, str)
                and harness.strip()
            ):
                location = state_location(
                    root or workspace, harness, session, state_dir
                )
                with locked_state(
                    location, min(deadline, time.monotonic() + 2)
                ) as state:
                    if identity is not None:
                        key = (
                            str(event["turn_id"])
                            if event.get("turn_id")
                            else "prompt:" + str(identity)
                        )
                        state["current_turn"] = key
                    else:
                        # No native admission identity: deduplicate only the
                        # reminder for this session, without granting another
                        # correction or inventing a new turn from prompt text.
                        key = state.get("current_turn", "unknown-turn")
                    deliver_reminder = state.get("reminder_turn") != key
                    state["reminder_turn"] = key
            return result(
                "allow",
                reminder(event, policy) if deliver_reminder else "",
            )
        if kind in {"reminder", "research"}:
            return result("allow", reminder(event, policy))
        if kind not in {"start", "pre", "post", "stop"}:
            return result()
        session = event.get("session_id")
        harness = event.get("harness")
        if (
            not isinstance(session, str)
            or not session.strip()
            or not isinstance(harness, str)
            or not harness.strip()
        ):
            if kind in {"post", "stop"}:
                return result(
                    "notify",
                    "Session identity unavailable; audit state is not shared",
                    pending=True,
                )
            value = result()
        else:
            location = state_location(root or workspace, harness, session, state_dir)
            lock_deadline = (
                min(deadline, time.monotonic() + 2) if kind == "pre" else deadline
            )
            with locked_state(location, lock_deadline) as state:
                try:
                    value = audit(event, policy, state, root, deadline)
                except (HookError, OSError) as exc:
                    state["pending"] = True
                    state.pop("checked", None)
                    if kind == "stop":
                        value = stop_result(
                            event,
                            state,
                            [{"kind": "hook_error", "message": str(exc)}],
                            True,
                        )
                    else:
                        raise
                if kind == "start" and not state.get("session_context_delivered"):
                    value["message"] = "\n\n".join(
                        part
                        for part in (
                            handover(workspace),
                            reminder(event, policy),
                        )
                        if part
                    )
                    state["session_context_delivered"] = True
                if (
                    kind == "pre"
                    and harness == "grok"
                    and not state.get("context_delivered")
                ):
                    value["message"] = "\n\n".join(
                        part
                        for part in (
                            handover(workspace),
                            reminder(event, policy),
                        )
                        if part
                    )
                    state["context_delivered"] = True
        if root is None and kind in {"post", "stop"} and value["action"] == "allow":
            value = result(
                "notify",
                "Git checks are unavailable in this non-Git workspace",
                pending=False,
            )
        if kind == "start" and not (
            isinstance(session, str)
            and session.strip()
            and isinstance(harness, str)
            and harness.strip()
        ):
            context = handover(workspace)
            value["message"] = "\n\n".join(
                part for part in (context, reminder(event, policy)) if part
            )
        return value
    except (
        HookError,
        _loop_module.LoopError,
        OSError,
        ValueError,
        TypeError,
        subprocess.TimeoutExpired,
    ) as exc:
        # A failed pre classifier must not silently approve the tool operation.
        action = "deny" if kind == "pre" else "notify"
        return result(
            action,
            f"Hook could not finish: {exc}",
            [{"kind": "hook_error", "message": str(exc)}],
            True,
        )


def read_payload(stream=None, timeout=2):
    """Read bounded JSON from a hook pipe, even when its writer stalls."""
    stream = stream or sys.stdin
    deadline = time.monotonic() + timeout
    data = bytearray()
    descriptor = stream.fileno()
    while True:
        remaining = deadline - time.monotonic()
        if (
            remaining <= 0
            or not select.select([descriptor], [], [], max(0, remaining))[0]
        ):
            raise HookError("Hook input timeout")
        block = os.read(descriptor, min(65536, MAX_INPUT + 1 - len(data)))
        if not block:
            break
        data.extend(block)
        if len(data) > MAX_INPUT:
            raise HookError("Hook input exceeds size limit")
    return json.loads(data)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--harness", required=True)
    parser.add_argument("--event", required=True)
    args = parser.parse_args(argv)
    from adapters import emit, event_kind, normalize

    actual_harness = args.harness
    try:
        payload = read_payload()
        delivery_events = {
            "LoopValidateDelivery": None,
            "LoopClaimDelivery": None,
            "LoopDeliveryAccepted": "accepted",
            "LoopDeliveryUnknown": "unknown",
            "LoopDeliveryAborted": "aborted",
        }
        if args.event in delivery_events:
            native = dict(
                payload,
                harness=args.harness,
                workspace=payload.get("workspace") or payload.get("cwd") or os.getcwd(),
                session_id=payload.get("session_id") or payload.get("sessionID"),
            )
            request_id = payload.get("request_id")
            if args.event == "LoopValidateDelivery":
                print(json.dumps({"valid": validate_delivery(native, request_id)}))
            elif args.event == "LoopClaimDelivery":
                print(json.dumps({"claimed": claim_delivery(native, request_id)}))
            else:
                print(
                    json.dumps(
                        {
                            "recorded": finish_delivery(
                                native, request_id, delivery_events[args.event]
                            )
                        }
                    )
                )
            return 0
        event = normalize(args.harness, args.event, payload)
        actual_harness = event["harness"]
        value = handle_event(event)
    except (HookError, ValueError, TypeError, OSError) as exc:
        try:
            pre = event_kind(args.event) == "pre"
        except ValueError:
            pre = False
        value = result(
            "deny" if pre else "notify", f"Malformed hook input: {exc}", pending=True
        )
    try:
        output, code = emit(actual_harness, args.event, value)
    except (ValueError, TypeError) as exc:
        # Malformed auto-dispatch input has no safely resolved native schema.
        # Exit 2 rejects pre operations in the shared command-hook contracts.
        print(value["message"] or f"Cannot emit hook response: {exc}", file=sys.stderr)
        return 2 if value["action"] == "deny" else 0
    if isinstance(output, dict):
        print(json.dumps(output, ensure_ascii=False))
    elif isinstance(output, str) and output:
        print(output, file=sys.stderr if code else sys.stdout)
    if value["action"] == "notify" and value["message"] and not isinstance(output, str):
        print(value["message"], file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
