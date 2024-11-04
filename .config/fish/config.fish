if not status is-interactive; exit; end;
# commands to run in interactive sessions go here

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
    # get all the appropriate versions from the filesystem
    # https://stackoverflow.com/a/57485303
    # set array
    # access elements with $array[INDEX]
    set -l python_versions
    for pv in (ls -1 /usr/bin/python* | grep '.*[0-9]\.\([0-9]\+\)\?$' | sort --version-sort)
        set -a python_versions "$pv" # append to array
    end

    set vpip_fname "$(mktemp)"
    set venv_dir "$HOME/.vpip"
    # create functions for each version
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
            set pv_dir \"$venv_dir/v$pv_num\"
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

function __venv_activate_fish
    set activate_fish "$(find . -maxdepth 3 -name "activate.fish" | head -n 1)"
    if test -e "$activate_fish"; echo "fish --init-command \"source $activate_fish\""; return 0; end
    return 1
end

#############################################################
# SOURCES & CONFIG
# add executable script (lambdas) dir
fish_add_path -g ~/dotfiles/scripts/functions/
# add login shell requirements if they're part of the regular install,
#  aka found at the $PATH above
if type -q require-login-shell-packages
    require-login-shell-packages
end
# add virtual pip functions
require-pip
# supress greeting
set -g fish_greeting ""

#############################################################
# ABBREVIATIONS & ALIAS

# dir up
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."

abbr --position command --add egrep "grep -E"
abbr --position command --add grep "grep -i"
abbr --position command --add rm "rm -v"
abbr --position command --add reverse "tac"
abbr --position command --add palindrome "rev"

function __sudo_last_command; echo "sudo $history[1]"; end
function __last_command; echo "$history[1]"; end
abbr --position command --add fuck --function __sudo_last_command
abbr --position command --add !! --function __last_command
abbr --position command --add vpip --function __venv_activate_fish

if type -q wget
    abbr --position command --add wget "wget -c --read-timeout=5 --tries=0 --cut-file-get-vars --content-disposition"
end

if type -q npm
    abbr --position command --add npm "npm --loglevel silly"
end

# chromium depot_tools, add to PATH only if they actually exist
#  https://chromium.googlesource.com/chromium/tools/depot_tools.git
if type -q locate and (locate --version) and (locate --limit 1 depot_tools)
    fish_add_path -g (locate --limit 1 depot_tools)
    abbr --position command --add fetch "fetch --no-history"
end

if type -q zoxide
    zoxide init fish | source
    abbr --position command --add cd "z"
end

if type -q lsd
    abbr --position command --add lss "lsd --almost-all --icon never --group-directories-first"
end

if type -q hx
    abbr --position command --add helix "hx"
    set -gx VISUAL hx
    set -gx EDITOR hx
end
