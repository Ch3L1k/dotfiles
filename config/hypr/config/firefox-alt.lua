-- Reserve Alt chords for desktop actions only while Firefox is focused.
-- No submap/catchall: ordinary typing can never be trapped by a missed release.
local guarded = {}
local enabled = nil
local modifier_codes = { [37]=true, [50]=true, [62]=true, [64]=true,
                         [105]=true, [108]=true, [133]=true, [134]=true }
local function firefox_active()
    local window = hl.get_active_window()
    return window ~= nil and tostring(window.class):lower():find("firefox", 1, true) ~= nil
end
local function update_guard()
    local next_enabled = firefox_active()
    if enabled == next_enabled then return end
    enabled = next_enabled
    for _, binding in ipairs(guarded) do binding:set_enabled(enabled) end
end
local function consume() end
-- Physical codes cover all layouts. Modifier keys themselves always pass through.
-- Existing desktop binds also match and keep executing their normal actions.
for code = 8, 255 do
    if not modifier_codes[code] then
        for _, mods in ipairs({ "ALT", "ALT + SHIFT", "ALT + CTRL", "ALT + CTRL + SHIFT" }) do
            local binding = hl.bind(mods .. " + code:" .. code, consume)
            binding:set_enabled(false)
            guarded[#guarded + 1] = binding
        end
    end
end
if hl.get_current_submap() == "firefox-alt-guard" then
    hl.dispatch(hl.dsp.submap("reset"))
end
hl.on("window.active", update_guard)
hl.on("config.reloaded", update_guard)
update_guard()
