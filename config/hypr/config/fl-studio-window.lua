-- FL Studio only. No key bindings, submaps or input hooks.
hl.window_rule({
    name = "fl-studio-appearance",
    match = { class = "^steam_app_flstudio$" },
    opacity = "1.0 override 1.0 override",
    no_blur = true,
})


-- FL reports its current size as both min and max under Wine.
-- Let Hyprland resize the main window normally in either layout mode.
hl.window_rule({
    name = "fl-studio-resizable",
    match = { class = "^steam_app_flstudio$", title = "^(.* - )?FL Studio 2025$" },
    min_size = { "320", "240" },
    no_max_size = true,
    persistent_size = false,
})

-- FL's filename hover tips are unnamed, override-redirect windows.
-- Wine marks them input-capable despite WS_EX_NOACTIVATE; keep compositor
-- focus on the editor. Menus still receive pointer input and route keys via FL.
hl.window_rule({
    name = "fl-studio-popup-focus",
    match = { class = "^steam_app_flstudio$", title = "^$" },
    no_focus = true,
})
