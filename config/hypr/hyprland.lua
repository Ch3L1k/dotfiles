-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.environment")
require("config.inputs")
require("config.binds")
require("config.misc")
require("config.monitors")
require("config.windowrules")
require("config.workspaces")

-- For Noctalia Color templates
require("noctalia").apply_theme()

require("config.firefox-alt")

require("config.keybind-toggle")

-- Keep manual economy effects across reloads, including palette updates.
local economy = require("config.session-power").economy
if next(economy.options or {}) then hl.config(economy.options) end

-- Forward side button as Space in the dedicated Wplace Firefox only.
dofile('@HOME@/Documents/Codex/2026-11-07/weplace-live-google-chrome-firefox-chrome/outputs/wplace-side-button.lua')
