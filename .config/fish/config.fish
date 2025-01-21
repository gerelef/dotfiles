if not status is-interactive
    exit
end
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
                    fish --init-command \"source \$pv_dir/bin/activate.fish; pip install --upgrade setuptools wheel pip; exit\"
                else
                    # for python >= 3
                    command $pv -m venv \$pv_dir
                    fish --init-command \"source \$pv_dir/bin/activate.fish; pip install --upgrade setuptools wheel pip; exit\"
                end
            end
            fish --init-command \"source \$pv_dir/bin/activate.fish\"
        end
        "
        # append to the file
        echo "$virtual_subshell" >>"$vpip_fname"
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
    if test -e "$activate_fish"
        echo "fish --init-command \"source $activate_fish\""
        return 0
    end
    return 1
end

#############################################################
# SOURCES & CONFIG
# add executable script (lambdas) dir
fish_add_path -g ~/dotfiles/scripts/functionz/
fish_add_path -g ~/bin
fish_add_path -g ~/.local/bin
# add virtual pip functions
require-pip
# source cargo environment if it exists
test -f "$HOME/.cargo/env.fish" && source "$HOME/.cargo/env.fish"

function _install-optional-shell-requirements --description 'install optional shell requirements'
    # the current .*rc config will work without them,
    #  but these are significant QOL upgrades over the regular terminal experience
    if ! type -q pkcon
        echo "Cannot invoke 'pkcon' (part of PackageKit), packages CANNOT be installed! " 1>&2
        return 1
    end
    # zoxide is used as a reference point for echoing out a helpful tip on startup, see below
    pkcon install --allow-reinstall zoxide lsd plocate
end

# suppress regular greeting
set -g fish_greeting ""

type -q _install-required-functionz-requirements && set functionz_postfix "\n Invoke '_install-required-functionz-requirements' to install dotfile's functionz dependencies."
type -q zoxide || echo -e "Welcome to fi/sh! Invoke '_install-optional-shell-requirements' to install QoL enhancements.$functionz_postfix"

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
abbr --position command --add reverse tac
abbr --position command --add palindrome rev

function __sudo_last_command; echo "sudo $history[1]"; end
abbr --position command --add fuck --function __sudo_last_command
abbr --position command --add vpip --function __venv_activate_fish
# same functionality as !! from bash
function __last_command; echo "$history[1]"; end
abbr --position command --add !! --function __last_command

type -q wget && abbr --position command --add wget "wget -c --read-timeout=5 --tries=0 --cut-file-get-vars --content-disposition"
type -q npm && abbr --position command --add npm "npm --loglevel silly"

# chromium depot_tools, add to PATH only if they actually exist
#  https://chromium.googlesource.com/chromium/tools/depot_tools.git
if locate --version 2>/dev/null 1>&2 && locate --limit 1 depot_tools 2>/dev/null 1>&2
    fish_add_path -g (locate --limit 1 depot_tools)
    abbr --position command --add fetch "fetch --no-history"
end

if type -q vi
    set -gx VISUAL vi
    set -gx EDITOR vi
end

if type -q vim
    set -gx VISUAL vim
    set -gx EDITOR vim
end

if type -q nvim
    set -gx VISUAL nvim
    set -gx EDITOR nvim
end

if type -q hx
    set -gx VISUAL hx
    set -gx EDITOR hx
end

if type -q zoxide
    zoxide init fish | source
    abbr --position command --add cd z
end

if type -q lsd
    abbr --position command --add lss "lsd -A --group-dirs=first --blocks=permission,user,group,date,name --date '+%d/%m %H:%M:%S'"
end

if locate --version 2>/dev/null 1>&2 && type -q fzf
    set WITH_LOCAL_DB ''
    if test -f ~/.locate.db
        set WITH_LOCAL_DB "-d ~/.locate.db"
    end
    abbr --set-cursor=% --add locate "locate $WITH_LOCAL_DB -i '%' | fzf"
    abbr --position command --add updatedb 'updatedb --require-visibility 0 -o ~/.locate.db'
end
