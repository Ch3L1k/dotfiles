hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
local saved = DISPLAY_MODE.monitors or {}
local power = require("config.session-power")
local function normal_rule(output, fallback_mode, fallback_position)
    local prior_name = output == MONITOR1 and DISPLAY_MODE.external or DISPLAY_MODE.internal
    local monitor = saved[output] or saved[prior_name] or {}
    local manual_mode = (power.manual.monitors or {})[output]
    -- A newly selected single-screen preset wins over older manual frequency settings.
    -- A later manual frequency choice can still override that preset.
    if EXTERNAL_ONLY and output == MONITOR1
        and (DISPLAY_MODE.changed_at or 0) > (power.manual.changed_at or 0) then
        manual_mode = nil
    end
    return {
        output = output,
        disabled = false,
        mode = (power.economy.monitors or {})[output] or manual_mode or monitor.mode or fallback_mode,
        position = monitor.position or fallback_position,
        scale = monitor.scale or 1,
        transform = monitor.transform or 0,
    }
end
local laptop = normal_rule(MONITOR2, "preferred", "0x0")
if EXTERNAL_ONLY then
    hl.monitor(normal_rule(MONITOR1, "1920x1080@60", "0x0"))
    hl.monitor({ output = MONITOR2, disabled = true })
elseif LAPTOP_ONLY then
    laptop.position = "0x0"
    hl.monitor(laptop)
    if DISPLAY_EXTERNAL_CONNECTED then hl.monitor({ output = MONITOR1, disabled = true }) end
else
    hl.monitor(normal_rule(MONITOR1, DISPLAY_EXTERNAL_DEFAULT or "preferred", "1920x0"))
    hl.monitor(laptop)
end

-- A disconnected external display must not leave the laptop without a screen.
hl.on("monitor.added", function(m)
    if m.name ~= MONITOR1 and (m.description or ""):find("MSI MP252", 1, true) then
        hl.exec_cmd("hyprctl reload config-only")
    elseif not DISPLAY_EXTERNAL_CONNECTED and m.name ~= MONITOR2 and m.name ~= "FALLBACK" then
        hl.exec_cmd("hyprctl reload config-only")
    end
end)
hl.on("monitor.removed", function(m)
    if m.name ~= MONITOR1 then return end
    if EXTERNAL_ONLY then
        hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/toggle-main-monitor --recover-external")
    elseif not LAPTOP_ONLY then
        hl.exec_cmd("hyprctl reload config-only")
    end
end)
