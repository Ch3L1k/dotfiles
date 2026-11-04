# Конфиги 4EL1k

Мой рабочий стол: CachyOS, Hyprland 0.56.2 с Lua-конфигурацией и native Noctalia
v5.4.0. Здесь оформление, бинды, Fastfetch, Kitty/Fish, темы и вспомогательные
скрипты. Данные аккаунтов, история и точная геолокация исключены.

Это подборка конфигов, а не установщик всего дистрибутива. Программы, шрифты
и плагины Noctalia устанавливаются отдельно. Для старого Hyprland с .conf или
Noctalia v4 на Quickshell эти файлы не подходят напрямую.

Показать, что будет скопировано, без изменений:

```sh
python3 install.py
```

Поставить только Fastfetch, Kitty и Fish:

```sh
python3 install.py --apply --component fastfetch --component kitty --component fish
```

Скопировать весь основной набор:

```sh
python3 install.py --apply
```

Перед перезагрузкой конфигурации проверь названия мониторов `DP-6` / `eDP-1`,
распределение рабочих столов, экран уведомлений и команды приложений.
Старые файлы сохраняются в `~/.local/state/dotfiles-backups/<дата-время>`.
Скрипт сам ничего не запускает, не перезагружает и не ставит через sudo.
Для автозапуска Telegram/Discord/Steam нужен отдельный выбор компонента:
`python3 install.py --apply --component autostart`.

Основная клавиша — Alt. Super+Space переключает EN/RU, Super+Alt+Space включает
украинский. Alt+M — музыка поверх окон, Ctrl+Shift+Esc — btop.
Super+Alt+Esc отключает и возвращает все бинды, кроме самого себя.
Полный список сочетаний и зависимостей есть в [README](README.md).

[Наши живые ASCII-обои](https://github.com/Ch3L1k/creation-of-tux) публикуются
отдельно, чтобы их можно было поставить и без этих конфигов.
