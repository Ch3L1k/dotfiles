-- Consume extra wheel ticks without restarting or queueing workspace slides.
local M = {}
local busy = false
-- Minimum pause between accepted wheel steps.
local cooldown_ms = 220

function M.step(direction, move_window)
    if busy then return false end
    if move_window and not hl.get_active_window() then return false end
    busy = true
    hl.timer(function() busy = false end, { timeout = cooldown_ms, type = "oneshot" })
    if move_window then
        hl.dispatch(hl.dsp.window.move({ workspace = direction, follow = false }))
    else
        hl.dispatch(hl.dsp.focus({ workspace = direction }))
    end
    return true
end

return M
