if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
else
    function fish_greeting
        if type -q fastfetch
            fastfetch
        end
    end
end
