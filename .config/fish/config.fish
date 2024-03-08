if status is-interactive
    # Commands to run in interactive sessions can go here
    #############################################################
    # SOURCES & CONFIG
    set -g fish_greeting ""
    # add executable script (lambdas) dir 
    fish_add_path -g ~/dotfiles/scripts/functions/
    # add requirements
    require-login-shell-packages

    #############################################################
    # ALIAS
    alias .. "cd .."
    alias ... "cd ../.."
    alias .... "cd ../../.."
    alias ..... "cd ../../../.."

    alias lss "lsd --almost-all --icon never --icon-theme unicode --group-directories-first"
    alias wget "\wget -c --read-timeout=5 --tries=0"
    alias grep "\grep -i"
    alias rm "rm -v"
    alias reverse "tac"
    alias palindrome "rev"
    
    alias fuck "sudo $history[2]"
end
