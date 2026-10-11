#!/usr/bin/env python3
"""Install and start Happier without replacing native agent settings."""

import argparse
import fcntl
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

INSTALLER = "https://raw.githubusercontent.com/happier-dev/happier/main/scripts/release/installers/install.sh"


def daemon_states(root):
    result = []
    for path in root.rglob("daemon.state.json") if root.exists() else []:
        state = json.loads(path.read_text())
        try:
            os.kill(int(state["pid"]), 0)
        except ProcessLookupError:
            continue
        result.append((state, path))
    return result


def daemon_sessions(state):
    port = int(state["httpPort"])
    if not 0 < port < 65536:
        raise RuntimeError("Invalid daemon control port")
    headers = {"Content-Type": "application/json"}
    if state.get("controlToken"):
        headers["x-happier-daemon-token"] = state["controlToken"]
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/list", data=b"{}", headers=headers
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=5) as response:
        value = json.load(response)
    sessions = value.get("children", value.get("sessions"))
    if not isinstance(sessions, list) or value.get("error"):
        raise RuntimeError("Cannot verify active sessions")
    return sessions


def install_happier(root):
    # Upstream verifies signed checksums. No npm, version pin, or shell edits.
    with tempfile.TemporaryDirectory(prefix="happier-installer-") as directory:
        script = Path(directory) / "install.sh"
        with urllib.request.urlopen(INSTALLER, timeout=30) as response:
            script.write_bytes(response.read())
        env = dict(
            os.environ,
            HAPPIER_INSTALL_DIR=str(root),
            HAPPIER_HOME_DIR=str(root),
            HAPPIER_BIN_DIR=str(Path.home() / ".local/bin"),
            HAPPIER_NO_PATH_UPDATE="1",
            HAPPIER_NONINTERACTIVE="1",
            HAPPIER_WITH_DAEMON="0",
            HAPPIER_CHANNEL="stable",
        )
        for name in (
            "HAPPIER_INSTALL_VERSION",
            "HAPPIER_INSTALLER_ACTION",
            "HAPPIER_INSTALLER_RUN_ACTION",
            "HAPPIER_PRODUCT",
        ):
            env.pop(name, None)
        subprocess.run(
            ["bash", str(script), "--stable", "--without-daemon", "--yes"],
            env=env,
            check=True,
        )
        subprocess.run([str(root / "bin/happier"), "--version"], env=env, check=True)


def sync_happier(root, binary):
    try:
        states = daemon_states(root)
        for state, _ in states:
            if daemon_sessions(state):
                print(
                    "Happier update deferred: active sessions; rerun after they finish."
                )
                return 0
        # CLI sessions may not have registered yet. Unknown processes defer updates.
        processes = subprocess.check_output(["ps", "-axo", "pid=,args="], text=True)
        ignored = {str(os.getpid()), *(str(state["pid"]) for state, _ in states)}
        for line in processes.splitlines():
            parts = line.strip().split(None, 1)
            if len(parts) != 2 or parts[0] in ignored:
                continue
            if str(root) + "/" in parts[1] and "remote-control.py" not in parts[1]:
                print("Happier update deferred: another Happier process is running.")
                return 0
        if states:
            if len(states) != 1:
                raise RuntimeError(
                    "Multiple daemons running; stop idle daemons before updating"
                )
            subprocess.run([binary, "daemon", "stop"], check=True, timeout=30)
            if daemon_states(root):
                raise RuntimeError("Daemon is still running; update deferred")
        try:
            install_happier(root)
        finally:
            if states:
                subprocess.run([binary, "daemon", "start"], check=True, timeout=45)
        return 0
    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        subprocess.SubprocessError,
    ) as error:
        print(f"Happier update failed: {error}", file=sys.stderr)
        return 1


def start_happier(root):
    binary = shutil.which("happier")
    # Shell startup must never initiate authentication.
    credentials = [root / "access.key", *root.glob("servers/*/access.key")]
    if not binary or not any(path.is_file() for path in credentials):
        return
    if not daemon_states(root):
        subprocess.run([binary, "daemon", "start"], check=True, timeout=45)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("sync", "start", "check"))
    args = parser.parse_args()
    data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    defaults = {
        "HAPPIER_HOME_DIR": data / "happier",
        "CLAUDE_CONFIG_DIR": config / "claude",
        "CODEX_HOME": config / "codex",
    }
    for name, value in defaults.items():
        os.environ.setdefault(name, str(value))
    root = Path(os.environ["HAPPIER_HOME_DIR"])
    root.mkdir(parents=True, exist_ok=True)
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents"
    cache.mkdir(parents=True, exist_ok=True)
    with (cache / "remote-control.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("Happier: another startup/update is in progress.")
            return 0
        if args.action == "sync":
            return sync_happier(
                root, shutil.which("happier") or str(root / "bin/happier")
            )
        if args.action == "start":
            start_happier(root)
        else:
            binary = shutil.which("happier")
            if not binary:
                print("happier: command not found", file=sys.stderr)
                return 1
            subprocess.run([binary, "--version"], check=True, timeout=30)
    return 0


if __name__ == "__main__":
    sys.exit(main())
