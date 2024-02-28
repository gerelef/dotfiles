if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path -g ~/dotfiles/scripts/functions/

    require-login-shell-packages

    set -g fish_greeting ""
    alias lss "lsd --almost-all --icon never --icon-theme unicode --group-directories-first"
    alias ... "cd ../../"
    alias .... "cd ../../../"
    alias ..... "cd ../../../../"
end
