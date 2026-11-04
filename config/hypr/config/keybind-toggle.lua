-- An input-transparent submap: only the toggle chord is registered here.
-- All other keys and mouse events are forwarded to applications normally.
local combo = "SUPER + ALT + Escape"
local paused_map = "desktop-hotkeys-disabled"
local function paused()
    return hl.get_current_submap() == paused_map
end
local function toggle()
    local disabled = not paused()
    hl.dispatch(hl.dsp.submap(disabled and paused_map or "reset"))
    local title = disabled and "Горячие клавиши отключены" or "Горячие клавиши включены"
    hl.dispatch(hl.dsp.exec_cmd("notify-send -a 'Горячие клавиши' -t 2500 '" .. title ..
        "' 'Super+Alt+Escape — переключить обратно'"))
end
local options = { locked = true, description = "Включить / отключить горячие клавиши" }
hl.bind(combo, toggle, options)
hl.define_submap(paused_map, function()
    hl.bind(combo, toggle, options)
end)
return { toggle = toggle, is_paused = paused }
