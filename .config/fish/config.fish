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
    set vpip_fname "/tmp/vpip-temp-$(date +%s%N).fish"
    set venv_dir "$HOME/.vpip"

    # # get all the appropriate versions from the filesystem
    # # https://stackoverflow.com/a/57485303
    # set array
    # access elements with $array[INDEX]
    set -l python_versions
    for pv in (ls -1 /usr/bin/python* | grep '.*[0-9]\.\([0-9]\+\)\?$' | sort --version-sort)
        set -a python_versions "$pv" # append to array
    end

    # create mock functions
    for pv in $python_versions
        # sanitize the filename and keep only the numbers at the end
        set pv_num $(echo $pv | tr -d -c 0-9.)

        set virtual_subshell "\
        function vpip$pv_num
            # don't run if it's root
            if test \"$EUID\" -eq 0
                echo \"Do NOT run as root!\"
                return 2
            end
            # create root dir if doesn't exist
            if not test -d \"$venv_dir\"
                echo \"Root $venv_dir doesn't exist; Creating it...\"
                mkdir -p \"$venv_dir\"
            end

            # if venv dir doesn't exist for our version create it
            set pv_dir \"$venv_dir/dvpip$pv_num\"
            if not test -d \"\$pv_dir\"
                echo \"Global \$pv_dir doesn't exist; creating venv for it!\"
                # the $pv expansion will execute, since it's expanded while making
                #  the stringified version of this function
                # special case of venv creation: 
                #  if python version < 3 (2.7 e.g.) use a special way for init

                # split on the dot (MAJOR.MINOR version spliterator)
                #  if there's no dot (???) in the version try to use pv as is
                set major_pv_num $(string split . $pv_num)[1]; or set major_pv_num $pv_num
                if test \$major_pv_num -lt 3
                    command $pv -m ensurepip --user
                    command $pv -m pip install virtualenv --user
                    command $pv -m virtualenv --python=\"$pv\" \"\$pv_dir\"
                else 
                    # for python >= 3
                    command $pv -m venv \$pv_dir
                end
            end
            fish --init-command \"source \$pv_dir/bin/activate.fish\"
        end
        "
        # append to the file
        echo "$virtual_subshell" >> "$vpip_fname"
    end

    echo "$vpip_fname"
end

function require-pip
    set vpip_fname "$(prepare-pip)"

    # source the file & delete
    source "$vpip_fname"
    rm "$vpip_fname"
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
abbr -a wget "wget -c --read-timeout=5 --tries=0"
abbr -a grep "grep -i"
abbr -a rm "rm -v"
abbr -a reverse "tac"
abbr -a palindrome "rev"
abbr -a unset "set --erase"

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."

alias fuck "sudo $history[2]"
