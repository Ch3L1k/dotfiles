-- Session-local state written atomically by toggle-main-monitor.
local runtime = os.getenv("XDG_RUNTIME_DIR") or ("/run/user/" .. tostring(os.getenv("UID") or "1000"))
local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
local ok, state = pcall(dofile, runtime .. "/hypr-display-toggle-" .. signature .. "/mode.lua")
if ok and type(state) == "table" then return state end
return { laptop_only = false, monitors = {} }
