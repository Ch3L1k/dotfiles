local runtime = os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000"
local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local function read(path)
    local ok, value = pcall(dofile, runtime .. path)
    if ok and type(value) == "table" and value.signature == signature then return value end
    return {monitors = {}, options = {}}
end
return {manual = read("/main-monitor-rate.lua"), economy = read("/battery-eco/overrides.lua")}
