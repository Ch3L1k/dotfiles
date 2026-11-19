-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd([[
        launcher="$HOME/.local/opt/noctalia-ascii/start"
        if [ -x "$launcher" ]; then exec "$launcher"; else exec /usr/bin/noctalia; fi
    ]])
end)
