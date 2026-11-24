-- Temporary compositor settings for the Waybar performance mode.
local background = "rgb(18191c)"
local active = "rgb(33363c)"
local text = "rgb(e7e9ec)"
local muted = "rgb(b4b8bf)"
local options = {
    ["general.gaps_in"] = 0,
    ["general.gaps_out"] = 0,
    ["general.border_size"] = 1,
    ["general.col.active_border"] = active,
    ["general.col.inactive_border"] = background,
    ["animations.enabled"] = false,
    ["decoration.rounding"] = 0,
    ["decoration.blur.enabled"] = false,
    ["decoration.shadow.enabled"] = false,
    ["decoration.dim_inactive"] = false,
    ["decoration.dim_special"] = 0,
    ["decoration.active_opacity"] = 1.0,
    ["decoration.inactive_opacity"] = 1.0,
    ["decoration.fullscreen_opacity"] = 1.0,
    ["group.col.border_active"] = active,
    ["group.col.border_inactive"] = background,
    ["group.col.border_locked_active"] = active,
    ["group.col.border_locked_inactive"] = background,
    ["group.groupbar.col.active"] = active,
    ["group.groupbar.col.inactive"] = background,
    ["group.groupbar.col.locked_active"] = active,
    ["group.groupbar.col.locked_inactive"] = background,
    ["group.groupbar.text_color"] = text,
    ["group.groupbar.text_color_inactive"] = muted,
    ["group.groupbar.text_color_locked_active"] = text,
    ["group.groupbar.text_color_locked_inactive"] = muted,
    ["misc.background_color"] = background,
    ["misc.disable_hyprland_logo"] = true,
    ["misc.disable_splash_rendering"] = true,
}

-- This rule is declared after app-specific opacity and rounding rules.
local rule = hl.window_rule({
    name = "desktop-performance-visuals",
    match = { class = ".*" },
    opacity = "1.0 override 1.0 override 1.0 override",
    force_rgbx = true,
    rounding = 0,
})
rule:set_enabled(false)

local previous
local mode = {}
function mode.enable()
    if not previous then
        local values = {}
        for option in pairs(options) do
            local value = hl.get_config(option)
            assert(value ~= nil, "Unknown Hyprland option: " .. option)
            values[option] = value
        end
        previous = values
    end
    hl.config(options)
    rule:set_enabled(true)
end

function mode.disable()
    rule:set_enabled(false)
    if previous then
        hl.config(previous)
        previous = nil
    end
end

-- A watched config reload creates a fresh Lua state. Reapply over the freshly
-- loaded normal settings while the current compositor has this marker.
local runtime = os.getenv("XDG_RUNTIME_DIR")
local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
if runtime and signature then
    local marker = io.open(runtime .. "/hypr/" .. signature .. "/desktop-performance-visuals", "r")
    if marker then
        marker:close()
        mode.enable()
    end
end

return mode
