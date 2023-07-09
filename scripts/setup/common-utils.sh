#!/usr/bin/env bash

if [[ -n "$__UTILS_LOADED" ]]; then
    return 0
fi
readonly __UTILS_LOADED="__LOADED"

shopt -s globstar
shopt -s dotglob
shopt -s nullglob

if [[ -n "$SUDO_USER" ]]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

# https://unix.stackexchange.com/questions/247576/how-to-get-home-given-user
readonly REAL_USER_HOME=$(eval echo "~$REAL_USER")
# dotfiles directories
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly RC_DIR=$(realpath -s "$SCRIPT_DIR/..")
readonly CONFIG_DIR=$(realpath -s "$SCRIPT_DIR/../../.config")
readonly RC_MZL_DIR="$CONFIG_DIR/mozilla"

# home directories to create
readonly CLONED_ROOT="$REAL_USER_HOME/cloned"
readonly MZL_ROOT="$REAL_USER_HOME/.mozilla/firefox"
readonly SSH_ROOT="$REAL_USER_HOME/.ssh"
readonly BIN_ROOT="$REAL_USER_HOME/bin"
readonly WRK_ROOT="$REAL_USER_HOME/work"
readonly SMR_ROOT="$REAL_USER_HOME/seminar"
readonly RND_ROOT="$REAL_USER_HOME/random"

dnf-install () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-INSTALL---------------- $*" | tr " " "\n"
    while : ; do
        dnf install -y --best --allowerasing $@ && break
    done
    echo "Finished installing."
)

dnf-install-group () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-GROUP-INSTALL---------------- $*" | tr " " "\n"
    while : ; do
        dnf groupinstall -y --best --allowerasing $@ && break
    done
    echo "Finished group-installing."
)

dnf-update-refresh () (
    echo "-------------------DNF-UPDATE----------------"
    while : ; do
        dnf update -y --refresh && break
    done
    echo "Finished updating."
)

dnf-remove () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-REMOVE---------------- $*" | tr " " "\n"
    dnf remove -y --skip-broken $@
    echo "Finished removing."
)

flatpak-install () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    echo "-------------------FLATPAK-INSTALL-SYSTEM---------------- $*" | tr " " "\n"
    while : ; do
        su - "$REAL_USER" -c "flatpak install --system -y $@" && break
    done
    echo "Finished flatpak-installing."
)

change-ownership () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown "$REAL_USER" "$@"
    chmod 700 "$@"
)

change-ownership-recursive () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown -R "$REAL_USER" "$@"
    chmod -R 700 "$@"
)

copy-dnf () (
    command cp -r "$CONFIG_DIR/dnf.conf" "/etc/dnf/dnf.conf"
    chown root "/etc/dnf/dnf.conf"
    chmod 644 "/etc/dnf/dnf.conf"
)

# man 5 sysctl.d
#    CONFIGURATION DIRECTORIES AND PRECEDENCE
#    ...
#    All configuration files are sorted by their filename in lexicographic order, regardless of which of the directories they reside in. 
#    If multiple files specify the same option, the entry in the file with the lexicographically latest name will take precedence. 
#    It is recommended to prefix all filenames with a two-digit number and a dash, to simplify the ordering of the files.

lower-swappiness () (
    echo "vm.swappiness = 10" > "/etc/sysctl.d/90-swappiness.conf"
)

raise-user-watches () (
    echo "fs.inotify.max_user_watches = 600000" > "/etc/sysctl.d/90-max_user_watches.conf"
)

raise-memory-map-counts () (
    # Increase the number of memory map areas a process may have. No need for it in fedora 39 or higher. Relevant links:
    # https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount
    # https://wiki.archlinux.org/title/gaming
    # https://kernel.org/doc/Documentation/sysctl/vm.txt
    echo "vm.max_map_count=2147483642" > "/etc/sysctl.d/90-max_map_count.conf"
)

cap-nproc-count () (
    [[ -z "$REAL_USER" ]] && return 0;
    
    echo "$REAL_USER hard nproc 10000" > "/etc/security/limits.d/90-nproc.conf"
)

cap-max-logins-system () (
    echo "* - maxsyslogins 5" > "/etc/security/limits.d/90-maxsyslogins.conf"
)

create-convenience-sudoers () (
    local fname="/etc/sudoers.d/convenience-defaults"
    
    echo "Defaults timestamp_timeout=120, pwfeedback" > "$fname"
    chmod 440 "$fname" # 440 is the default rights of /etc/sudoers file, so we're copying the rights just in case (even though visudo -f /etc/sudoers.d/test creates the file with 640)
)

create-private-bashrc () (
    touch "$REAL_USER_HOME/.bashrc-private"
    change-ownership "$REAL_USER_HOME/.bashrc-private"
)

create-private-gitconfig () (
    touch "$REAL_USER_HOME/.gitconfig-github"
    touch "$REAL_USER_HOME/.gitconfig-gitlab"
    touch "$REAL_USER_HOME/.gitconfig-gnome"
    
    change-ownership "$REAL_USER_HOME/.gitconfig-github"
    change-ownership "$REAL_USER_HOME/.gitconfig-gitlab"
    change-ownership "$REAL_USER_HOME/.gitconfig-gnome"
)

copy-rc-files () (
    ln -sf "$RC_DIR/.vimrc" "$REAL_USER_HOME/.vimrc"
    ln -sf "$RC_DIR/.bashrc" "$REAL_USER_HOME/.bashrc"
    ln -sf "$RC_DIR/.nanorc" "$REAL_USER_HOME/.nanorc"
    ln -sf "$CONFIG_DIR/.gitconfig" "$REAL_USER_HOME/.gitconfig"
    change-ownership "$REAL_USER_HOME/.vimrc" "$REAL_USER_HOME/.bashrc" "$REAL_USER_HOME/.nanorc" "$REAL_USER_HOME/.gitconfig"
)

copy-ff-rc-files () (
    mkdir -p "$CLONED_ROOT/mono-firefox-theme"
    echo "Created $CLONED_ROOT/mono-firefox-theme/"
    readonly RC_VIS_MZL_DIR="$CLONED_ROOT/mono-firefox-theme"
    # if something goes wrong, install the next version, otherwise break
    wget -c --read-timeout=5 --tries=0 --directory-prefix "$CLONED_ROOT/" "https://github.com/witalihirsch/Mono-firefox-theme/releases/download/0.5/mono-firefox-theme.tar.xz"
    tar -xf "$CLONED_ROOT/mono-firefox-theme.tar.xz" --directory="$RC_VIS_MZL_DIR"
    echo "Extracted $CLONED_ROOT/mono-firefox-theme.tar.xz"
    rm -vf "$CLONED_ROOT/mono-firefox-theme.tar.xz"
    cat "$RC_MZL_DIR/userChrome.css" >> "$RC_VIS_MZL_DIR/userChrome.css"
    echo "Installing visual rc files from $RC_VIS_MZL_DIR"

    #https://askubuntu.com/questions/239543/get-the-default-firefox-profile-directory-from-bash
    if [[ $(grep '\[Profile[^0]\]' "$MZL_ROOT/profiles.ini") ]]; then
        readonly PROFPATH=$(grep -E '^\[Profile|^Path|^Default' "$MZL_ROOT/profiles.ini" | grep '^Path' | cut -c6- | tr " " "\n")
    else
        readonly PROFPATH=$(grep 'Path=' "$MZL_ROOT/profiles.ini" | sed 's/^Path=//')
    fi

    for MZL_PROF_DIR in $PROFPATH; do
        MZL_PROF_DIR_ABSOLUTE="$MZL_ROOT/$MZL_PROF_DIR"
        MZL_PROF_CHROME_DIR_ABSOLUTE="$MZL_PROF_DIR_ABSOLUTE/chrome"

        # preference rc
        ln -sf "$RC_MZL_DIR/user.js" "$MZL_PROF_DIR_ABSOLUTE/user.js"
        change-ownership "$MZL_PROF_DIR_ABSOLUTE/user.js"

        # visual rc
        mkdir -p "$MZL_PROF_CHROME_DIR_ABSOLUTE"
        ln -sf "$RC_VIS_MZL_DIR/userChrome.css" "$MZL_PROF_CHROME_DIR_ABSOLUTE/userChrome.css"
        ln -sf "$RC_VIS_MZL_DIR/userContent.css" "$MZL_PROF_CHROME_DIR_ABSOLUTE/userContent.css"
        ln -sf "$RC_VIS_MZL_DIR/mono-firefox-theme" "$MZL_PROF_CHROME_DIR_ABSOLUTE/mono-firefox-theme"
    done
)


