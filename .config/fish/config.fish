if not status is-interactive; exit; end;
# Commands to run in interactive sessions can go here

#############################################################
# PYTHON VENV(s)

# goal: we want to create alot of different vpipN () (...) functions to call
#  for every different virtual environment that we have; e.g. python3.11 will have vpip3.11
#  which calls for the activation of the virtual environment of python3.11 stored somewhere on the system
#  to do that, we're going to 
#   (1) create a mock file 
#   (2) dump all these different functions in it
#   (3) source it 
#   (4) then promptly delete it so we don't create garbage files & for (perhaps) obscure security reasons
#   these functions (which only differ by the python version they're calling) should:
#      (1) check if a venv (for this specific version) exists in the venv directory. If it doesn't, 
#        (1a) create a new venv for this specific version
#      (2) source the activation script (and enter the venv)

# important note: the statement pythonX.x -m venv \"\$venv_dir\" won't work with 2.7 or lower,
#  for that, we need the virtualenv module
function prepare-pip
    # vpip_fname="/tmp/vpip-temp-$(date +%s%N).sh"
    # venv_dir="$HOME/.vpip"
    # python_versions=()

    # # get all the appropriate versions from the filesystem
    # # https://stackoverflow.com/a/57485303
    # for pv in "$(ls -1 /usr/bin/python* | grep '.*[0-9]\.\([0-9]\+\)\?$' | sort --version-sort)"; do
    #     python_versions+=("$pv")
    # done

    # # create mock functions
    # for python_version in $python_versions; do
    #     # sanitize the filename and keep only the numbers at the end
    #     python_version_number="$(echo $python_version | tr -d -c 0-9.)"

    #     virtual_group_subshell="vpip$python_version_number () {
    #         [[ \"\$EUID\" -eq 0 ]] && echo \"Do NOT run as root.\" && return 2; 
    #         [[ ! -d \"$venv_dir\" ]] && mkdir -p \"$venv_dir\" # create root dir if doesn't exist
    #         local venv_dir=\"$venv_dir/dvpip$python_version_number\"

    #         # if venv dir doesn't exist for our version create it
    #         if [[ ! -d \"\$venv_dir\" ]]; then
    #             echo \"\$venv_dir doesn't exist; creating venv for $python_version\"

    #             # special case of the trick below: if python version < 3 (2.7 e.g.) use a special way for venv init
    #             if [[ ${python_version_number%.*} -lt 3 ]]; then
    #                 $python_version  -m ensurepip --user
    #                 $python_version -m pip install virtualenv --user
    #                 $python_version -m virtualenv --python=\"$python_version\" \"\$venv_dir\"
    #             else
    #                 $python_version -m venv \"\$venv_dir\" # for python >= 3
    #             fi
    #         fi

    #         bash --init-file <(echo \"source \\\"$HOME/.bashrc\\\"; source \$venv_dir/bin/activate\")
    #     }"

    #     # append to the file
    #     echo "$virtual_group_subshell" >> $vpip_fname
    # done

    # echo "$vpip_fname"
end

function require-pip
    # local vpip_fname="$(prepare-pip)"

    # # source the file & delete
    # source "$vpip_fname"
    # rm "$vpip_fname"
end

#############################################################
# SOURCES & CONFIG
# add executable script (lambdas) dir 
fish_add_path -g ~/dotfiles/scripts/functions/
# add login shell requirements
require-login-shell-packages
# add virtual pip functions
require-pip
# supress greeting
set -g fish_greeting ""

#############################################################
# ABBREVIATIONS & ALIAS
abbr -a lss "lsd --almost-all --icon never --group-directories-first"
abbr -a wget "\wget -c --read-timeout=5 --tries=0"
abbr -a grep "\grep -i"
abbr -a rm "rm -v"
abbr -a reverse "tac"
abbr -a palindrome "rev"

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."

alias fuck "sudo $history[2]"
