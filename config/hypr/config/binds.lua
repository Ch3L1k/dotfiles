local mainMod = "ALT"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- "

local function bind(keys, action, description, flags)
    flags = flags or {}
    flags.description = description
    flags.submap_universal = false
    hl.bind(keys, action, flags)
end
local function shell(keys, command, description, flags)
    bind(keys, hl.dsp.exec_cmd(noctCall .. command), description, flags)
end
local function app(keys, command, description)
    bind(keys, hl.dsp.exec_cmd(launchPrefix .. command), description)
end

app(mainMod .. " + Q", TERMINAL, "Терминал")
app(mainMod .. " + SHIFT + Q", "cool-retro-term", "Ретро-терминал")
app(mainMod .. " + B", BROWSER, "Браузер")
app(mainMod .. " + G", "chatgpt", "ChatGPT")
app(mainMod .. " + E", FILE_MANAGER, "Файловый менеджер")
app(mainMod .. " + SHIFT + E", TERMINAL .. " -e yazi", "Yazi")
app(mainMod .. " + T", "Telegram", "Telegram")
app(mainMod .. " + D", "discord", "Discord")
app(mainMod .. " + SHIFT + T", EDITOR, "Текстовый редактор")
shell(mainMod .. " + F8", "plugin amirfarzamnia/autoclicker:service all toggle", "Автокликер: включить / выключить")
shell(mainMod .. " + SHIFT + F8", "plugin amirfarzamnia/autoclicker:service all stop", "Остановить автокликер", { locked = true })
app("XF86Calculator", CALCULATOR, "Калькулятор")
local special_app = os.getenv("HOME") .. "/.local/bin/toggle-special-app "
bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(special_app .. "btop"), "Показать / скрыть btop поверх окон")
bind(mainMod .. " + M", hl.dsp.exec_cmd(special_app .. "music"), "Показать / скрыть YouTube Music поверх окон")

local language = os.getenv("HOME") .. "/.local/bin/switch-desktop-language "
bind("SUPER + Space", hl.dsp.exec_cmd(language .. "toggle"), "Раскладка: русский / английский")
bind("SUPER + ALT + Space", hl.dsp.exec_cmd(language .. "ukrainian"), "Украинская раскладка")

bind(mainMod .. " + C", hl.dsp.window.close(), "Закрыть окно")
bind("SUPER + ALT + C", hl.dsp.window.kill(), "Принудительно завершить приложение")
bind(mainMod .. " + F", hl.dsp.window.fullscreen(), "Полный экран")
bind(mainMod .. " + SHIFT + D", hl.dsp.window.fullscreen({ mode = 1 }), "Развернуть окно")
bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }), "Плавающее окно / тайлинг")
bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), "Повернуть разделение окон")
bind("ALT + Tab", hl.dsp.window.cycle_next(), "Следующее окно")

for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
    bind(mainMod .. " + " .. direction,
        hl.dsp.focus({ direction = direction:lower() }), "Фокус: " .. direction)
    bind(mainMod .. " + SHIFT + " .. direction,
        hl.dsp.window.move({ direction = direction:sub(1, 1):lower() }), "Переместить окно: " .. direction)
end
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), "Перетащить окно")
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Изменить размер окна")

-- 1–8: MSI; 9–10: laptop. The 0 key selects workspace 10.
for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }), "Рабочий стол " .. workspace)
    bind(mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = workspace, follow = false }), "Окно на рабочий стол " .. workspace)
end
-- Reversed wheel direction; consume ticks until the slide is nearly finished.
local workspace_wheel = require("config.workspace-wheel")
bind(mainMod .. " + mouse_up", function() workspace_wheel.step("m-1") end, "Предыдущий стол: Alt + колесо вперёд")
bind(mainMod .. " + mouse_down", function() workspace_wheel.step("m+1") end, "Следующий стол: Alt + колесо назад")
bind(mainMod .. " + SHIFT + mouse_up", function() workspace_wheel.step("m-1", true) end, "Окно на предыдущий стол: Alt+Shift+колесо вперёд")
bind(mainMod .. " + SHIFT + mouse_down", function() workspace_wheel.step("m+1", true) end, "Окно на следующий стол: Alt+Shift+колесо назад")
bind(mainMod .. " + CONTROL + Left", hl.dsp.focus({ workspace = "m-1" }), "Предыдущий стол на мониторе")
bind(mainMod .. " + CONTROL + Right", hl.dsp.focus({ workspace = "m+1" }), "Следующий стол на мониторе")
bind(mainMod .. " + CONTROL + Up", hl.dsp.focus({ monitor = PRIMARY_MONITOR }), "Основной монитор")
bind(mainMod .. " + CONTROL + Down", hl.dsp.focus({ monitor = MONITOR2 }), "Монитор ноутбука")
bind(mainMod .. " + SHIFT + M",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/toggle-main-monitor"),
    "Внешний монитор / только экран ноутбука")
app(mainMod .. " + S", "@HOME@/.local/bin/steam", "Steam")

shell(mainMod .. " + Space", "panel-toggle launcher", "Запуск приложений")
shell(mainMod .. " + V", "panel-toggle clipboard", "История буфера обмена")
shell(mainMod .. " + X", "panel-toggle control-center", "Центр управления")
shell(mainMod .. " + A", "panel-toggle control-center notifications", "Уведомления")
shell(mainMod .. " + comma", "settings-toggle", "Настройки Noctalia")
shell(mainMod .. " + L", "session lock", "Заблокировать экран")
shell("CONTROL + ALT + Delete", "panel-toggle session", "Меню питания и выхода")
shell(mainMod .. " + SHIFT + W", "panel-toggle wallpaper", "Выбор обоев")

shell("Print", "screenshot-region", "Скриншот области")
shell("SUPER + SHIFT + S", "screenshot-region", "Скриншот области")
shell(mainMod .. " + Print", "screenshot-fullscreen", "Скриншот монитора")
bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"), "Выбрать цвет")

local hardware = {
    { "XF86AudioRaiseVolume", "volume-up", "Громче", true },
    { "XF86AudioLowerVolume", "volume-down", "Тише", true },
    { "XF86AudioMute", "volume-mute", "Включить / выключить звук" },
    { "XF86AudioMicMute", "mic-mute", "Включить / выключить микрофон" },
    { "XF86AudioPlay", "media toggle", "Пауза / воспроизведение" },
    { "XF86AudioPause", "media toggle", "Пауза / воспроизведение" },
    { "XF86AudioNext", "media next", "Следующий трек" },
    { "XF86AudioPrev", "media previous", "Предыдущий трек" },
    { "XF86MonBrightnessUp", "brightness-up", "Ярче", true },
    { "XF86MonBrightnessDown", "brightness-down", "Темнее", true },
}
for _, item in ipairs(hardware) do
    shell(item[1], item[2], item[3], { locked = true, repeating = item[4] or false })
end

-- Do not pass throttled Alt+wheel events through to the focused application.
hl.config({ binds = { scroll_event_delay = 0 } })
