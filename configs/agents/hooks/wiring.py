# isort: skip_file
"""Merge common hook registrations without changing user trust or selections.

This installer never executes repository commands or grants hook trust. Native
configuration writes are atomic and malformed files are rejected before writes.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import shlex
import stat
import sys
import tempfile
import tomllib
from pathlib import Path

LEGACY = {"load-handover.sh", "remind-websearch.sh", "generate-handover.sh"}


def managed(handler):
    command = handler.get("command", handler.get("bash", ""))
    if not isinstance(command, str):
        return False
    try:
        words = shlex.split(command)
    except ValueError as error:
        raise ValueError("Malformed shell command in hook configuration") from error
    for word in words:
        normalized = word.replace("${HOME}", "$HOME")
        if (
            "/.agents/hooks/" in normalized or normalized.startswith("~/.agents/hooks/")
        ) and normalized.rsplit("/", 1)[-1] in LEGACY | {"common_hook.py"}:
            return True
    return False


def merge_hooks(current, desired):
    """Preserve state, unrelated handlers and disabled common registrations."""
    if not isinstance(current, dict) or not isinstance(desired, dict):
        raise ValueError("hooks must be an object")  # noqa: TRY004 - Config validation contract.
    output = copy.deepcopy(current)
    for event, additions in desired.items():
        if not isinstance(additions, list):
            raise ValueError(f"Expected hook list for {event}")  # noqa: TRY004 - Config validation contract.
        existing = output.get(event, [])
        if not isinstance(existing, list):
            raise ValueError(f"Expected hook list for {event}")  # noqa: TRY004 - Config validation contract.
        kept = []
        disabled = []
        for entry in existing:
            if not isinstance(entry, dict):
                raise ValueError(f"Invalid hook entry for {event}")  # noqa: TRY004 - Config validation contract.
            if "hooks" in entry:
                handlers = entry["hooks"]
                if not isinstance(handlers, list) or not all(
                    isinstance(h, dict) for h in handlers
                ):
                    raise ValueError(f"Invalid hook handlers for {event}")
                owned = [h for h in handlers if managed(h)]
                other = [h for h in handlers if not managed(h)]
                if entry.get("enabled") is False and owned:
                    disabled.append(copy.deepcopy(entry))
                elif other:
                    kept.append(dict(entry, hooks=other))
                for h in owned:
                    if h.get("enabled") is False:
                        disabled.append(dict(entry, hooks=[copy.deepcopy(h)]))
            elif managed(entry):
                if entry.get("enabled") is False:
                    disabled.append(copy.deepcopy(entry))
            else:
                kept.append(copy.deepcopy(entry))
        # A deliberate disabled registration is not enabled by installation.
        if disabled:
            output[event] = kept + disabled
            continue
        identities = set()
        for entry in kept:
            for handler in entry.get("hooks", [entry]):
                identities.add(
                    (
                        entry.get("matcher", ""),
                        handler.get("type", "command"),
                        handler.get(
                            "command", handler.get("bash", handler.get("exec", ""))
                        ),
                    )
                )
        for entry in copy.deepcopy(additions):
            handlers = entry.get("hooks", [entry])
            fresh = []
            for handler in handlers:
                identity = (
                    entry.get("matcher", ""),
                    handler.get("type", "command"),
                    handler.get(
                        "command", handler.get("bash", handler.get("exec", ""))
                    ),
                )
                if identity not in identities:
                    fresh.append(handler)
                    identities.add(identity)
            if fresh:
                kept.append(dict(entry, hooks=fresh) if "hooks" in entry else entry)
        output[event] = kept
    return output


def merge_json(current, desired, kind="standard"):
    if not isinstance(current, dict) or not isinstance(desired, dict):
        raise ValueError("Configuration must be a JSON object")  # noqa: TRY004 - Config validation contract.
    output = copy.deepcopy(current)
    if kind == "antigravity":
        definition = output.get("common-agents", {})
        if not isinstance(definition, dict):
            raise ValueError("Invalid common-agents definition")
        enabled = definition.get("enabled")
        definition = merge_hooks(definition, desired["common-agents"])
        if enabled is not None:
            definition["enabled"] = enabled
        output["common-agents"] = definition
    else:
        output["hooks"] = merge_hooks(output.get("hooks", {}), desired["hooks"])
        if "version" in desired:
            output.setdefault("version", desired["version"])
    return output


def dump_toml(value):
    import tomlkit

    text = tomlkit.dumps(value)
    if tomllib.loads(text) != value:
        raise ValueError("TOML round-trip verification failed")
    return text


def merge_toml_text(current_text, desired_text):
    """Keep the declarative document's comments and original table spellings."""
    import tomlkit

    current = tomlkit.parse(current_text)
    document = tomlkit.parse(desired_text)
    result = merge_toml(current.unwrap(), document.unwrap())
    if current_text and current.unwrap() == result:
        return current_text

    def update(target, values, reference):
        for key, value in values.items():
            if key in target and target[key] == value:
                continue
            if (
                key in target
                and isinstance(value, dict)
                and isinstance(target[key], dict)
            ):
                update(target[key], value, reference.get(key, {}))
            elif key not in target and key in reference and reference[key] == value:
                target[key] = copy.deepcopy(reference[key])
            else:
                target[key] = value

    update(document, result, current)
    text = tomlkit.dumps(document)
    if tomllib.loads(text) != result:
        raise ValueError("TOML merge round-trip verification failed")
    return text


def merge_toml(current, desired):
    output = copy.deepcopy(current)

    def merge(left, right):
        for key, value in right.items():
            if isinstance(value, dict) and isinstance(left.get(key), dict):
                merge(left[key], value)
            else:
                left[key] = copy.deepcopy(value)

    desired = copy.deepcopy(desired)
    desired_hooks = desired.pop("hooks", {})
    hooks = merge_hooks(output.get("hooks", {}), desired_hooks)
    merge(output, desired)
    if hooks:
        output["hooks"] = hooks
    return output


def atomic_write(path, text):
    """Replace only the destination, never follow a mutable config symlink."""
    if path.is_dir():
        raise ValueError(f"Configuration is a directory: {path}")
    mode = (
        stat.S_IMODE(path.stat().st_mode)
        if path.exists() and not path.is_symlink()
        else 0o600
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".common-hooks-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def prepare_json(destination, template, kind="standard"):
    current = json.loads(destination.read_text()) if destination.exists() else {}
    desired = json.loads(template.read_text())
    output = merge_json(current, desired, kind)
    return destination, json.dumps(output, indent=2, ensure_ascii=False) + "\n"


def install_global(home, config, templates):
    # Preflight every JSON document before mutating any of the global files.
    writes = [
        prepare_json(
            home / ".gemini/config/hooks.json",
            templates / "antigravity/hooks.json",
            "antigravity",
        ),
        prepare_json(
            Path(os.environ.get("COPILOT_HOME", home / ".copilot"))
            / "hooks/common-agents.json",
            templates / "copilot/hooks/common-agents.json",
        ),
    ]
    # CLI 2.x hooks are profile scoped. Keep the selected agent, prompt, model,
    # tools and trust untouched. No built-in profile is silently shadowed.
    profiles = sorted((home / ".kiro/agents").glob("*.json"))
    for profile in profiles:
        writes.append(prepare_json(profile, templates / "kiro/common-hooks.json"))
    if not profiles:
        print(
            "common-hooks: Kiro 2.x has no user profile; global standalone hooks unsupported; no agent selection changed",
            file=sys.stderr,
        )
    for destination, text in writes:
        if (
            not destination.exists()
            or destination.read_text() != text
            or destination.is_symlink()
        ):
            atomic_write(destination, text)
    return len(writes)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    merge_parser = commands.add_parser("merge-toml")
    merge_parser.add_argument("--base", required=True, type=Path)
    merge_parser.add_argument("--destination", required=True, type=Path)
    merge_parser.add_argument("--local", type=Path)
    json_parser = commands.add_parser("merge-json")
    json_parser.add_argument("--base", required=True, type=Path)
    json_parser.add_argument("--destination", required=True, type=Path)
    json_parser.add_argument(
        "--kind", choices=("standard", "antigravity"), default="standard"
    )
    global_parser = commands.add_parser("global")
    global_parser.add_argument("--templates", required=True, type=Path)
    global_parser.add_argument("--home", type=Path, default=Path.home())
    global_parser.add_argument("--config", type=Path)
    args = parser.parse_args()
    try:
        if args.action == "global":
            install_global(
                args.home,
                args.config
                or Path(os.environ.get("XDG_CONFIG_HOME", args.home / ".config")),
                args.templates,
            )
        elif args.action == "merge-json":
            destination, text = prepare_json(args.destination, args.base, args.kind)
            atomic_write(destination, text)
        else:
            desired_text = args.base.read_text()
            if args.local and args.local.exists():
                desired_text = args.local.read_text() + "\n" + desired_text
            current_text = (
                args.destination.read_text() if args.destination.exists() else ""
            )
            atomic_write(args.destination, merge_toml_text(current_text, desired_text))
    except (OSError, ValueError, KeyError, ImportError) as error:
        print(f"common-hooks wiring: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
