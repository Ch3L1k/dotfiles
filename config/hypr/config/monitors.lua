hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
local saved = DISPLAY_MODE.monitors or {}
local power = require("config.session-power")
local function normal_rule(output, fallback_mode, fallback_position)
    local monitor = saved[output] or {}
    return {
        output = output,
        disabled = false,
        mode = (power.economy.monitors or {})[output] or (power.manual.monitors or {})[output] or monitor.mode or fallback_mode,
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
    hl.monitor({ output = MONITOR1, disabled = true })
else
    hl.monitor(normal_rule(MONITOR1, "1920x1080@120", "1920x0"))
    hl.monitor(laptop)
end

-- A disconnected external display must not leave the laptop without a screen.
hl.on("monitor.removed", function()
    if EXTERNAL_ONLY then
        hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/toggle-main-monitor --recover-external")
    end
end)
