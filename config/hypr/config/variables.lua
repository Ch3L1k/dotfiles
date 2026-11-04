-- Hyprland default apps

TERMINAL     = "kitty --single-instance --instance-group desktop"
FILE_MANAGER = "nautilus --new-window"
BROWSER      = "firefox"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Monitors
MONITOR1 = "DP-6"
MONITOR2 = "eDP-1"
MONITOR3 = ""
DISPLAY_MODE = require("config.display-mode")
MONITOR1 = DISPLAY_MODE.external or MONITOR1
MONITOR2 = DISPLAY_MODE.internal or MONITOR2
LAPTOP_ONLY = DISPLAY_MODE.laptop_only == true
PRIMARY_MONITOR = LAPTOP_ONLY and MONITOR2 or MONITOR1

-- Workspaces
NUM_WPM = 10 -- Total numbered workspaces
