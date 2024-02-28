if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting
    alias lss "lsd --almost-all --icon never --icon-theme unicode --group-directories-first"
end
