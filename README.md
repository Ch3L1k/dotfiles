# 4EL1k's dotfiles

My CachyOS + **Hyprland (Lua)** + **Noctalia v5** desktop configuration.
A curated, sanitized snapshot, with appearance settings, shortcuts and small
helpers. This is not a full home-directory or account backup.

[Русская инструкция](README.ru.md) · [Live ASCII wallpaper](https://github.com/Ch3L1k/creation-of-tux)

## Included

- **Hyprland:** Alt-based bindings, small gaps, borders, blur, animations,
  silent window moves, special workspaces, keyboard layout switching and a
  toggle to temporarily disable all desktop shortcuts.
- **Noctalia:** merged active bar/dock/panel settings, hover-only dock, primary
  monitor notifications, theme templates and local plugin overrides.
- **Kitty + Fish:** single-instance launcher bindings, shell greeting,
  Fastfetch and package-management shortcuts.
- **Fastfetch:** CachyOS ASCII logo, framed OS/Kernel/Shell/Terminal/WM/CPU/GPU/
  Memory/OS Age/Uptime keys and colored dots. Values are detected, not hardcoded.
- **GTK/Nautilus:** translucent backgrounds and current Noctalia palette.
- **btop/Yazi:** generated Noctalia colors.
- **Helpers:** special apps, monitor toggle, XWayland primary selection, Steam
  launcher, EXE/UMU launcher, Telegram background generation, folder icon colors,
  Codex desktop palette sync and screen-recording controls.
- **Optional autostart definitions:** Telegram, Discord and Steam; not selected
  by the installer unless requested explicitly.

## Before applying

This snapshot targets **Hyprland 0.56.2 with the Lua API** and **native Noctalia
v5.4.0** on CachyOS. It is not a drop-in .conf setup for older Hyprland or the
Quickshell-based Noctalia v4. App commands and monitor rules are personal
preferences; adjust them for your machine.

In `config/hypr/config/variables.lua`, the sample monitors are `DP-6` (external)
and `eDP-1` (laptop). Workspaces 1–8 are assigned to the external screen and 9–10
to the laptop. Review `monitors.lua`, `workspaces.lua` and Noctalia notification
monitor settings **before reloading**. Noctalia's listed community plugins must
be installed through its catalog; the small local overrides are included here.
Existing warnings for disabled/unavailable widgets may need cleanup for a
minimal setup. The snapshot does not bundle a modified Noctalia executable.

## Installation

Clone/download the repository, then preview the files:

```sh
python3 install.py
```

Install only the parts you want, for example:

```sh
python3 install.py --apply --component fastfetch --component kitty --component fish
```

Or copy the complete desktop set, excluding application autostart:

```sh
python3 install.py --apply
```

To opt into the three app autostart definitions:

```sh
python3 install.py --apply --component autostart
```

The installer expands `@HOME@` placeholders, preserves file backups under
`~/.local/state/dotfiles-backups/<timestamp>`, and copies selected files. It does
not install packages, change the login shell, enable services, run applications,
reload Hyprland or overwrite system files. You decide when to reload after
reviewing the copied configuration. Add `~/.local/bin` to PATH for the helpers.
Python 3.11+ is needed for helpers using `tomllib`.

Backups contain the previous files and a manifest. To undo a copy, restore only
the corresponding paths from that backup. A whole-directory restore would
also replace unrelated changes you may have made afterwards.

## Software used

Core: Hyprland (Lua API), native Noctalia v5, UWSM, Kitty, Fish, Fastfetch,
Nautilus, adw-gtk3, Adwaita icons, Nerd Font symbols, Python 3, jq, libnotify.
Optional: btop, Yazi, pavucontrol, Firefox, Telegram Desktop, Discord, Steam,
Pear Desktop, hyprpicker, swash, gpu-screen-recorder, UMU/GE-Proton and the
ChatGPT/Codex desktop application.

Dependencies differ by distribution. These dotfiles do not download or install
those programs, fonts, third-party plugins or account profiles.

## Main shortcuts

| Shortcut | Action |
| --- | --- |
| Alt+Q / B / E | Terminal / browser / new Nautilus window |
| Alt+Shift+E | Yazi |
| Alt+T / D / S / G | Telegram / Discord / Steam / ChatGPT |
| Alt+C / Super+Alt+C | Ask the window to close / force-kill it |
| Alt+1…0 | Workspaces 1…10 |
| Alt+Shift+1…0 | Move a window without following it |
| Alt+wheel | Previous/next workspace, throttled |
| Alt+Shift+wheel | Move a window without following it |
| Alt+M | YouTube Music special workspace |
| Ctrl+Shift+Escape | btop special workspace |
| Alt+Shift+M | External monitor ↔ laptop-only layout |
| Alt+Shift+Space | Floating/tiled window |
| Alt+X | Control center |
| Alt+Shift+W | Wallpaper picker |
| Super+Space | English/Russian cycle |
| Super+Alt+Space | Ukrainian layout |
| Super+Alt+Escape | Disable/re-enable desktop keybindings |

The Firefox Alt guard deliberately reserves most Alt chords for the desktop.
Leave out that Lua module if you prefer Firefox's normal Alt shortcuts.

## App themes and folder icons

Noctalia generates terminal, GTK, btop, Yazi and Fastfetch colors. The supplied
palette files are a starting snapshot; generated colors change with the theme.
Telegram/Vencord/Codex templates and helpers are supplied **without account data**.
Their UI/theme activation may still be needed inside each installed application.
The Codex helper writes only appearance preferences and does not restart the app.

Folder SVGs are not redistributed. To recreate the rounded folder colors from
your **installed Adwaita** sources, after installing the scripts and Noctalia:

```sh
gsettings set org.gnome.desktop.interface icon-theme Noctalia-Soft
~/.local/bin/noctalia-folder-icons
```

The included `zz-folder-icons.toml` hook updates them when Noctalia resolves a
new palette. No systemd file watcher is needed.

## Privacy and scope

See [PUBLICATION.md](PUBLICATION.md). No cookies, API tokens, SSH keys, browser
profiles, chats, Steam userdata, Telegram sessions or shell histories are included.
Wallpaper files, precise location, disk UUIDs/mounts, bootloader configuration and
old disabled background services are excluded. **Creation of Tux** has its own
repository and installer; the earlier personal wallpaper service is not copied.

## Credits and licenses

This is a collection with upstream components; see [LICENSE](LICENSE) for the
per-component scope. CachyOS/Hyprland base configuration, Noctalia, community
plugin authors and other original notices retain their authorship. Local plugin
manifests and README files are preserved. Custom helpers and adjustments were
developed with AI coding assistance for **4EL1k**.
