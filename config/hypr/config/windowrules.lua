-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Generic floating position
hl.window_rule({ match = { float = true }, persistent_size = true })

-- Picture-in-Picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    size              = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin               = true,
})

-- Gaming
local steamGames = "^steam_app_[1-9][0-9]*$"
local notSIGame = "negative:^steam_app_3553500$"
local launchWorkspace = "special:game-launch silent"

-- Wayland games can identify themselves without changing their chosen window mode.
hl.window_rule({ match = { xdg_tag = "^(.*game.*)$", initial_class = notSIGame }, content = "game" })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })

-- Unknown launcher and updater windows stay accessible without stealing focus.
hl.window_rule({
    match = {
        class = steamGames,
        initial_class = notSIGame,
        initial_title = [[(?i)^(?:.+ )?(?:launcher(?: updater)?|bootstrapper)(?::.*)?$]],
        modal = false,
    },
    float = true,
    center = true,
    no_initial_focus = true,
    suppress_event = "activate activatefocus fullscreen",
})

local function backgroundLauncher(match)
    hl.window_rule({
        match            = match,
        workspace        = launchWorkspace,
        float            = true,
        center           = true,
        fullscreen_state = 0,
        no_initial_focus = true,
        suppress_event   = "activate activatefocus fullscreen",
        render_unfocused = true,
    })
end

-- Only the observed, automatic progress windows belong on the hidden workspace.
backgroundLauncher({ initial_class = "^steam$", initial_title = [[^Launching\.{3}$]] })
backgroundLauncher({
    initial_class = "^steam_app_1174180$",
    initial_title = "^(|Rockstar Games Launcher|Rockstar Games [–—-] (Вход|Sign [Ii]n))$",
})
backgroundLauncher({
    initial_class = "^steam_app_250900$",
    initial_title = [[^(REPENTOGON Launcher|REPENTOGON Launcher Updater(:.*)?|Copying Mod files from Steam\.{3})$]],
})

hl.window_rule({
    match = { class = "^steam_app_[0-9]+$", initial_class = notSIGame, initial_title = "^$" },
    center = true,
    float = true,
    fullscreen = false,
    fullscreen_state = 0,
})

-- Keep the existing fullscreen behavior for the two verified game windows.
local function fullscreenGame(class, title)
    hl.window_rule({
        match            = { initial_class = class, initial_title = title },
        content          = "game",
        decorate         = false,
        fullscreen_state = 2,
        size             = { "monitor_w", "monitor_h" },
        sync_fullscreen  = true,
    })
end

fullscreenGame("^steam_app_1174180$", "^Red Dead Redemption 2$")
fullscreenGame("^steam_app_250900$", "^The Binding of Isaac(:.*)?$")

-- Apps
hl.window_rule({ match = { class = "^(Tor Browser)$" }, float = true })
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, monitor = PRIMARY_MONITOR, center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, float = true, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" } })
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.kde\\.ark)$" }, size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" } })
hl.window_rule({ match = { class = "^(.*swash)$", title = "^(Swash)$" }, min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" }, float = true })
hl.window_rule({ match = { class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$" }, float = true, size = { "monitor_w*0.70", "monitor_h*0.70" } })
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.dolphin)$",
        title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
    },
    float = true,
    size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
    move = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))", -- X axis clamping
        "max(20, min(cursor_y - 50, monitor_h - window_h + 20))" -- Y axis clamping
    },
})

-- Opacity Overrides
-- Telegram uses an opaque pre-blurred wallpaper: text and media never fade.
hl.window_rule({
    match = { class = "^(org\\.telegram\\.desktop)$" },
    opacity = "1.0 override 1.0 override",
    no_blur = false,
    rounding = 16,
})

-- Keep the comparison client's content opaque, with the same window corners.
hl.window_rule({
    match = { class = "^(io\\.github\\.kukuruzka165\\.materialgram)$" },
    opacity = "1.0 override 1.0 override",
    rounding = 16,
})

-- Keep Discord's glass stable when the pointer/focus moves to Telegram.
hl.window_rule({
    match = { class = "^(discord)$" },
    opacity = "0.95 override 0.95 override",
    no_blur = false,
})

-- These apps live outside the ten numbered workspaces.
hl.window_rule({ match = { class = "^(special-btop)$" }, workspace = "special:btop silent", float = false, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(com\\.github\\.th-ch\\.youtube-music|pear-desktop)$" }, workspace = "special:music silent", float = false })

local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

hl.window_rule({ match = { class = "^(firefox|zen)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = terminals }, opacity = "1.0 override" }) -- Override opacity in favor of terminal settings for opacity. If your terminal doesn't support transparency, you can remove this rule.
hl.window_rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Float Utility Windows
local floatApps = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}
for _, m in ipairs(floatApps) do hl.window_rule({ match = m, float = true }) end

-- Float Common Modals
local modalMatches = {
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$"},
}
for _, m in ipairs(modalMatches) do hl.window_rule({ match = m, float = true }) end

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Noctalia layer rule
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})

-- Nautilus draws translucent surfaces; keep text and icons fully opaque.
hl.window_rule({ match = { class = "^(org\\.gnome\\.Nautilus)$" }, opacity = "1.0 override" })

-- Dedicated FL Studio window rules; keyboard bindings are unchanged.
require("config.fl-studio-window")
