# Provenance and sanitization

Snapshot selected on **2026-11-04**, by **4EL1k**.

| Published area | Origin |
| --- | --- |
| config/hypr | Active CachyOS Hyprland Lua files, with local modifications |
| config/noctalia/config.toml | Active hand-written config merged with selected Noctalia settings sections |
| config/noctalia/templates | Custom app-theme templates used locally |
| config/kitty, fastfetch, GTK, btop, Yazi | Current appearance/configuration files; Noctalia-generated palette snapshots included |
| config/fish | Local shortcuts and a portable startup fallback |
| config/autostart | Three app launch definitions; Discord's version-specific path generalized |
| scripts | Selected local helper programs; no captured application state |
| plugins/record-controls | Local 4EL1k recorder panel |
| plugins/special-workspaces | Local override of jamesfeeder's MIT plugin |
| plugins/better-clock | Local override of yugaaank's MIT plugin |

Source paths are represented by standard `~/.config`, `~/.local/bin` and
`~/.local/share/noctalia/plugins`; exported templates replace the actual home
path with `@HOME@`. No raw settings database or home-directory archive is present.
The user-specific Noctalia wallpaper history, favorites, avatar and location
were not exported. Password-related lockscreen appearance controls were omitted
from the shared snapshot along with private account-related fields.

CachyOS base package source: https://github.com/CachyOS/cachyos-hypr-noctalia
Native Noctalia source: https://github.com/noctalia-dev/noctalia
Original local plugin authors and declared licenses are preserved in their
plugin.toml files and readmes. Templates are copied as small text files, not
an application profile. See LICENSE for the separate scope of original code
and upstream components. Original GNOME icon SVGs, font binaries, wallpaper
images and third-party application executables are not bundled.

The active installation was only read. The public snapshot omits the legacy
X access grant from autostart and portal permission overrides. No live desktop
configuration was changed by preparing or testing this repository.

Validation: Python helper syntax, TOML and JSON parsing; shell/Fish syntax where
applicable; Fastfetch parsing in an isolated config directory; 4 installer tests
using temporary destination homes. These checks do not claim that every app or
Noctalia plugin has been tested on a fresh distribution or different hardware.
