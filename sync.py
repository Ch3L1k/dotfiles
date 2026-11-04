#!/usr/bin/env python3
# Copyright (c) 2026 Ch3L1k. SPDX-License-Identifier: MIT
"""Update the existing dotfiles snapshot from this user's desktop settings."""

import argparse
import copy
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import tomllib

SECTIONS = {
    "accessibility", "bar", "battery", "bluetooth", "brightness", "control_center",
    "desktop_widgets", "dock", "lockscreen", "lockscreen_widgets", "notification",
    "osd", "plugin_settings", "plugins", "shell", "system", "theme", "widget",
}
PRIVATE_KEYS = re.compile(r"password|secret|api.?key|access.?token|refresh.?token|authorization|cookie|latitude|longitude|avatar_path|account_id|user_id|guild_id|channel_id|geolocation|coordinates", re.I)
CREDENTIALS = re.compile(r"gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}|sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{20,}|AIza[A-Za-z0-9_-]{30,}")


def git(repo, *args):
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
    result = subprocess.run(["git", "-C", str(repo), *args], env=env, text=True,
                            capture_output=True, timeout=120)
    if result.returncode:
        raise RuntimeError("git " + args[0] + ": " + result.stderr.strip()[:600])
    return result.stdout


def merge(base, overlay):
    result = copy.deepcopy(base)
    for key, value in overlay.items():
        result[key] = merge(result[key], value) if isinstance(result.get(key), dict) and isinstance(value, dict) else copy.deepcopy(value)
    return result


def clean(value, home):
    if isinstance(value, dict):
        return {key: clean(item, home) for key, item in value.items() if not PRIVATE_KEYS.search(key)}
    if isinstance(value, list):
        return [clean(item, home) for item in value]
    if isinstance(value, str):
        return "" if value.startswith("/run/media/") else value.replace(str(home), "@HOME@").replace("4EL1k", "Ch3L1k")
    return value


def toml_value(value):
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join(json.dumps(key) + " = " + toml_value(item) for key, item in value.items()) + "}"
    raise ValueError("Unsupported TOML value")


def noctalia(home):
    base = tomllib.loads((home / ".config/noctalia/config.toml").read_text())
    state = home / ".local/state/noctalia/settings.toml"
    overlay = tomllib.loads(state.read_text()) if state.is_file() else {}
    data = clean({key: value for key, value in merge(base, overlay).items() if key in SECTIONS}, home)
    data["wallpaper"] = {"directory": "@HOME@/Pictures/Wallpapers"}
    data.setdefault("shell", {}).update(show_location=False, external_ip_enabled=False)
    lines = ["# Desktop snapshot. Render @HOME@ with install.py."]
    for section, values in data.items():
        if not isinstance(values, dict):
            raise ValueError("Invalid Noctalia section: " + section)
        lines.append("\n[" + json.dumps(section) + "]")
        lines.extend(json.dumps(key, ensure_ascii=False) + " = " + toml_value(value) for key, value in values.items())
    result = "\n".join(lines) + "\n"
    assert tomllib.loads(result) == data
    return result


def snapshot(repo, home):
    result = {}
    tracked = git(repo, "ls-files", "-z", "config", "scripts", "plugins").split("\0")
    for name in filter(None, tracked):
        relative = Path(name)
        category, *parts = relative.parts
        if category == "config":
            source = home / ".config" / Path(*parts)
        elif category == "scripts":
            source = home / ".local/bin" / Path(*parts)
        else:
            source = home / ".local/share/noctalia/plugins" / Path(*parts)
        if source.is_symlink():
            raise ValueError("Review the linked config before syncing: " + name)
        if source.exists() and not source.is_file():
            raise ValueError("Expected a regular config file: " + name)
        if name == "config/noctalia/config.toml":
            text = noctalia(home)
        elif not source.exists():
            result[name] = None
            continue
        else:
            if source.stat().st_size > 2_000_000:
                raise ValueError("Config unexpectedly exceeds 2 MB: " + name)
            text = source.read_text().replace(str(home), "@HOME@").replace("4EL1k", "Ch3L1k")
        if name == "config/hypr/config/autostart.lua":
            text = "\n".join(line for line in text.splitlines() if "xhost +SI:localuser:root" not in line) + "\n"
        if name == "scripts/steam":
            text = re.sub(r"(?ms)^# Ember (?:Linux integration|native Steam installer \(lumalinux\))\nif \[ -r .*?\nfi\n", "", text)
        if name == "config/fish/config.fish":
            line = "source /usr/share/cachyos-fish-config/cachyos-config.fish"
            text = text.replace(line, "if test -f /usr/share/cachyos-fish-config/cachyos-config.fish\n    " + line + "\nend")
        if name == "config/autostart/discord.desktop":
            text = re.sub(r"(?m)^Exec=.*$", "Exec=discord", text)
            text = re.sub(r"(?m)^Icon=.*$", "Icon=discord", text)
        if CREDENTIALS.search(text):
            raise ValueError("Potential credential; publication stopped for review: " + name)
        result[name] = text.encode()
    return result


def sync(repo, home, apply=False, push=False):
    if git(repo, "branch", "--show-current").strip() != "main":
        raise ValueError("Automatic snapshot expects the main branch")
    if git(repo, "status", "--porcelain", "--untracked-files=no").strip():
        raise ValueError("The checkout has manual changes; automatic export left it untouched")
    files = snapshot(repo, home)
    changed = [name for name, data in files.items() if (repo / name).read_bytes() != data]
    if not (apply or push):
        return {"state": "preview", "changed": changed}
    if changed:
        for name in changed:
            target = repo / name
            if files[name] is None:
                target.unlink()
            else:
                pending = target.with_name(target.name + ".sync-tmp")
                pending.write_bytes(files[name])
                pending.chmod(target.stat().st_mode & 0o777)
                pending.replace(target)
        git(repo, "add", "--", *changed)
        stamp = datetime.datetime.now().astimezone().strftime("%Y-%m-%d")
        git(repo, "commit", "-m", "chore(dotfiles): update desktop configuration " + stamp)
    if push:
        expected = "https://github.com/Ch3L1k/dotfiles.git"
        if git(repo, "remote", "get-url", "origin").strip() != expected:
            raise ValueError("Unexpected remote; automatic push stopped")
        git(repo, "fetch", "--no-tags", "origin", "main")
        if git(repo, "rev-list", "HEAD..origin/main").strip():
            raise ValueError("GitHub contains newer commits; reconcile the checkout before syncing")
        git(repo, "push", "origin", "main")
    return {"state": "updated" if changed else "unchanged", "changed": changed,
            "commit": git(repo, "rev-parse", "--short", "HEAD").strip()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--push", action="store_true")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--source-home", type=Path, default=Path.home())
    args = parser.parse_args()
    state = args.source_home / ".local/state/dotfiles-sync"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "sync.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        try:
            result = sync(args.repo, args.source_home, args.apply, args.push)
        except Exception as error:
            result = {"state": "failed", "message": str(error)}
            (state / "last-run.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
            print(result["message"])
            raise SystemExit(1)
        (state / "last-run.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
