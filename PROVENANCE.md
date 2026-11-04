# Sources

Snapshot selected on **2026-11-04**, by **Ch3L1k**.

| Published area | Origin |
| --- | --- |
| config/hypr | Active CachyOS Hyprland Lua files, with local modifications |
| config/noctalia/config.toml | Active hand-written config merged with selected Noctalia settings sections |
| config/noctalia/templates | Custom app-theme templates used locally |
| config/kitty, fastfetch, GTK, btop, Yazi | Current appearance/configuration files; Noctalia-generated palette snapshots included |
| config/fish | Local shortcuts and a portable startup fallback |
| config/autostart | Three app launch definitions; Discord's version-specific path generalized |
| scripts | Selected local helper programs |
| plugins/record-controls | Local Ch3L1k recorder panel |
| plugins/special-workspaces | Local override of jamesfeeder's MIT plugin |
| plugins/better-clock | Local override of yugaaank's MIT plugin |

Home paths use `@HOME@` placeholders, expanded by the installer.

CachyOS base package source: https://github.com/CachyOS/cachyos-hypr-noctalia
Native Noctalia source: https://github.com/noctalia-dev/noctalia
Original local plugin authors and declared licenses are preserved in their
plugin.toml files and readmes. Templates are copied as small text files, not
an application profile. See LICENSE for the separate scope of original code
and upstream components. Original GNOME icon SVGs, font binaries, wallpaper
images and third-party application executables are not bundled.

Validation: Python helper syntax, TOML and JSON parsing; shell/Fish syntax where
applicable; Fastfetch parsing in an isolated config directory; 4 installer tests
using temporary destination homes. These checks do not claim that every app or
Noctalia plugin has been tested on a fresh distribution or different hardware.
