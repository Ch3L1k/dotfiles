-- Hyprland default apps

TERMINAL     = "kitty --single-instance --instance-group desktop"
FILE_MANAGER = "nautilus --new-window"
BROWSER      = "firefox"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Monitors
DISPLAY_MODE = require("config.display-mode")
-- DRM exposes physical connections even before Hyprland has an output list,
-- and even when a connected panel is disabled by the current layout.
local function read(path, format)
    local file = io.open(path, "rb")
    if not file then return nil end
    local data = file:read(format)
    file:close()
    return data
end
local internal, external, external_rank = nil, nil, 0
local connectors = io.popen("/usr/bin/ls -d /sys/class/drm/card*-*/status 2>/dev/null", "r")
if connectors then
    for path in connectors:lines() do
        local name = path:match("/card%d+%-(.+)/status$")
        if name and read(path, "*l") == "connected" then
            if name:match("^eDP%-") or name:match("^LVDS%-") then
                internal = name
            else
                local edid = read(path:gsub("status$", "edid"), 128) or ""
                local rank = edid:find("MSI MP252", 1, true) and 3 or (name == DISPLAY_MODE.external and 2 or 1)
                if rank > external_rank then external, external_rank = name, rank end
            end
        end
    end
    connectors:close()
end
MONITOR1 = external or "desc:Microstep MSI MP252 E2"
MONITOR2 = internal or DISPLAY_MODE.internal or "desc:AU Optronics 0x139D"
MONITOR3 = ""
DISPLAY_EXTERNAL_CONNECTED = external ~= nil
DISPLAY_EXTERNAL_DEFAULT = external_rank == 3 and "1920x1080@120" or "preferred"
LAPTOP_ONLY = DISPLAY_MODE.laptop_only == true or (internal ~= nil and not external)
EXTERNAL_ONLY = external ~= nil and DISPLAY_MODE.external_only == true
PRIMARY_MONITOR = LAPTOP_ONLY and MONITOR2 or MONITOR1

-- Workspaces
NUM_WPM = 10 -- Total numbered workspaces
