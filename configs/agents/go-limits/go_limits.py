#!/usr/bin/env python3
"""OpenCode Go usage per window: five-hour, weekly and monthly.

Tries the API key (zen/go/v1/usage), then the opencode Console sign-in
(console/api/go/status), then the opencode-quota TUI export. Both routes are
the ones opencode-quota 5.0.3 reads; neither is documented. No secret is
printed: errors carry only the route and the HTTP status.
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import UTC, datetime
from pathlib import Path

KEY_URL = "https://opencode.ai/zen/go/v1/usage"
CONSOLE = "https://opencode.ai/console"
TIMEOUT = 5
WINDOWS = (
    ("5h", "rolling", "fiveHour"),
    ("weekly", "weekly", "week"),
    ("monthly", "monthly", "month"),
)
EXPORT_WINDOWS = {"5h", "weekly", "monthly"}


class RouteError(Exception):
    pass


class NotSubscribed(Exception):
    pass


def get_json(url, token, extra=None):
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            # Cloudflare answers some user agents with error 1010
            "User-Agent": "opencode",
            **(extra or {}),
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        body = b""
        try:
            body = error.read()
        except OSError:
            pass
        raise RouteError(f"HTTP {error.code}", error.code, body) from None
    except (TimeoutError, urllib.error.URLError) as error:
        reason = getattr(error, "reason", error)
        raise RouteError(
            "timeout" if isinstance(reason, TimeoutError) else "request failed"
        ) from None
    except ValueError:
        raise RouteError("invalid JSON") from None


def _window(name, used, resets, status):
    if not isinstance(used, (int, float)) or not 0 <= used <= 100:
        raise RouteError(f"bad {name} percent")
    if isinstance(resets, str):
        try:
            resets = datetime.fromisoformat(resets).timestamp()
        except ValueError:
            raise RouteError(f"bad {name} reset") from None
    exhausted = status == "rate-limited"
    return {
        "window": name,
        "used": 100 if exhausted else round(used),
        "status": status,
        "resetAt": int(resets) if isinstance(resets, (int, float)) else None,
    }


def from_key(key):
    try:
        body = get_json(KEY_URL, key)
    except RouteError as error:
        if len(error.args) > 2 and error.args[1] == 403:
            try:
                payload = json.loads(error.args[2])
                if (
                    payload.get("type") == "error"
                    and payload.get("error", {}).get("type") == "EntitlementError"
                ):
                    raise NotSubscribed from None
            except (ValueError, AttributeError):
                pass
        raise
    usage = body.get("usage") if isinstance(body, dict) else None
    if not isinstance(usage, dict):
        raise RouteError("no usage")
    windows = []
    for name, key_name, _ in WINDOWS:
        item = usage.get(key_name)
        if not isinstance(item, dict) or item.get("status") not in (
            "ok",
            "rate-limited",
        ):
            raise RouteError(f"bad {name} window")
        windows.append(
            _window(name, item.get("percent"), item.get("resetsAt"), item["status"])
        )
    return windows


def console_credential():
    try:
        out = subprocess.run(
            ["opencode", "auth", "export", "opencode"],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise RouteError("opencode auth export failed") from None
    try:
        rows = json.loads(out.stdout) if out.returncode == 0 else None
    except ValueError:
        rows = None
    if not isinstance(rows, list):
        raise RouteError("opencode auth export failed")
    for row in sorted(rows, key=lambda row: not row.get("active")):
        value = row.get("value") or {}
        if (
            value.get("type") == "oauth"
            and isinstance(value.get("access"), str)
            and value["access"]
        ):
            return value
    raise RouteError("no console sign-in")


def from_console():
    value = console_credential()
    metadata = value.get("metadata") or {}
    base = metadata.get("server") or CONSOLE
    extra = (
        {"x-org-id": metadata["orgID"]}
        if isinstance(metadata.get("orgID"), str)
        else {}
    )
    try:
        body = get_json(f"{base.rstrip('/')}/api/go/status", value["access"], extra)
    except RouteError as error:
        if len(error.args) > 1 and error.args[1] == 404:
            raise NotSubscribed from None
        raise
    access = body.get("access") if isinstance(body, dict) else None
    if not isinstance(access, dict):
        raise NotSubscribed
    meters = access.get("meters")
    if not isinstance(meters, dict):
        raise RouteError("no meters")
    windows = []
    for name, _, meter_name in WINDOWS:
        meter = meters.get(meter_name)
        try:
            limit, used = (
                float(meter["limitMicroCents"]),
                float(meter["usedMicroCents"]),
            )
        except (KeyError, TypeError, ValueError):
            raise RouteError(f"bad {name} meter") from None
        percent = (
            (100 if used > 0 else 0)
            if limit <= 0
            else min(100, max(0, used / limit * 100))
        )
        windows.append(
            _window(
                name,
                percent,
                meter.get("resetsAt") or access.get("endsAt"),
                "rate-limited" if percent >= 100 else "ok",
            )
        )
    return windows


def from_export(path):
    try:
        go = json.loads(Path(path).read_text()).get("providers", {}).get("opencode-go")
    except (OSError, ValueError, AttributeError):
        raise RouteError("no export") from None
    if not isinstance(go, dict) or not isinstance(go.get("entries"), list):
        raise RouteError(f"export opencode-go {(go or {}).get('status', 'missing')}")
    windows = []
    for entry in go["entries"]:
        name = str(entry.get("window", "")).lower()
        if name not in EXPORT_WINDOWS or entry.get("renderType") != "percent":
            continue
        remaining = entry.get("percentRemaining")
        if not isinstance(remaining, (int, float)):
            continue
        windows.append(
            _window(
                name,
                100 - remaining,
                entry.get("resetAt"),
                "rate-limited" if remaining <= 0 else "ok",
            )
        )
    if not windows:
        raise RouteError("export has no windows")
    return windows, go.get("fetchedAt")


def export_path():
    return (
        Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
        / "opencode/quota-export.json"
    )


def collect(now=None):
    now = time.time() if now is None else now
    errors = []
    key = os.environ.get("OPENCODE_API_KEY", "").strip()
    routes = ([("key", lambda: from_key(key))] if key else []) + [
        ("console", from_console)
    ]
    for source, fetch in routes:
        try:
            return {
                "status": "ok",
                "source": source,
                "age": 0,
                "windows": fetch(),
                "errors": errors,
            }
        except NotSubscribed:
            return {
                "status": "not_subscribed",
                "source": source,
                "age": 0,
                "windows": [],
                "errors": errors,
            }
        except RouteError as error:
            errors.append(f"{source}: {error.args[0]}")
    if not key:
        errors.insert(0, "key: OPENCODE_API_KEY unset")
    try:
        windows, fetched = from_export(export_path())
        age = max(0, int(now - fetched)) if isinstance(fetched, (int, float)) else None
        return {
            "status": "ok",
            "source": "export",
            "age": age,
            "windows": windows,
            "errors": errors,
        }
    except RouteError as error:
        errors.append(f"export: {error.args[0]}")
    return {
        "status": "unknown",
        "source": None,
        "age": None,
        "windows": [],
        "errors": errors,
    }


def line(result):
    if result["status"] != "ok":
        return f"opencode-go quota {result['status'].replace('_', ' ')} ({'; '.join(result['errors']) or result['source']})"
    parts = []
    for window in result["windows"]:
        reset = ""
        if window["resetAt"] is not None:
            reset = f", resets {datetime.fromtimestamp(window['resetAt'], UTC).astimezone():%m-%d %H:%M}"
        flag = " RATE-LIMITED" if window["status"] == "rate-limited" else ""
        parts.append(f"{window['window']} {window['used']}% used{reset}{flag}")
    age = (
        "live"
        if result["source"] != "export"
        else (
            f"{result['age'] // 60}m old"
            if result["age"] is not None
            else "age unknown"
        )
    )
    return f"opencode-go via {result['source']} ({age}): {'; '.join(parts)}"


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="go-limits", description=__doc__.splitlines()[0]
    )
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    parser.add_argument(
        "--threshold",
        type=float,
        default=80,
        help="exit 1 when a window reaches this used percent (default 80)",
    )
    args = parser.parse_args(argv)
    result = collect()
    print(json.dumps(result) if args.json else line(result))
    if result["status"] != "ok":
        return 2
    return (
        1
        if any(window["used"] >= args.threshold for window in result["windows"])
        else 0
    )


if __name__ == "__main__":
    sys.exit(main())
