# Package commands retain their normal confirmation prompts.
alias ff 'fastfetch'
alias pac 'sudo pacman -S'
alias y 'yay -S'

alias pacs 'pacman -Ss'
alias paci 'pacman -Qi'
alias ys 'yay -Ss'
alias upd 'yay -Syu'
alias c 'clear'

function mkcd --description 'Создать папку и перейти в неё'
    if test (count $argv) -ne 1
        printf 'Использование: mkcd путь_к_папке\n' >&2
        return 2
    end
    command mkdir -p -- "$argv[1]"; and cd -- "$argv[1]"
end
