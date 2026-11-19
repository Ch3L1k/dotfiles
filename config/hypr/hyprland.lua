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

-- Let Noctalia update just the palette without reloading monitors and workspaces.
-- Hyprland watches modules resolved by Lua's file searcher. This generated
-- palette is read explicitly; the regular configuration modules stay watched.
package.preload.noctalia = function()
    local path = assert(package.searchpath("noctalia", package.path))
    local theme = dofile(path)
    package.loaded.noctalia = theme
    return theme
end

-- For Noctalia Color templates
require("noctalia").apply_theme()

require("config.firefox-alt")

require("config.keybind-toggle")

-- Keep manual economy effects across reloads, including palette updates.
local economy = require("config.session-power").economy
if next(economy.options or {}) then hl.config(economy.options) end
