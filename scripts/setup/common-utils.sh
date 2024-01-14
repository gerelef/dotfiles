# check if this file is being executed directly & if it is, die
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tput setaf 1
    tput bold
    echo "common-utils is NOT supposed to be executed directly!"
    echo "To use, please source it from another script!"
    tput sgr0
    exit 2
fi

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

# https://stackoverflow.com/a/47126974
readonly REAL_USER_UID=$(id -u ${REAL_USER})
# https://unix.stackexchange.com/questions/247576/how-to-get-home-given-user
readonly REAL_USER_HOME=$(eval echo "~$REAL_USER")
readonly REAL_USER_DBUS_ADDRESS="unix:path=/run/user/${REAL_USER_UID}/bus"
# fs thingies
readonly ROOT_FS=$(stat -f --format=%T /)
readonly REAL_USER_HOME_FS=$(stat -f --format=%T "$REAL_USER_HOME")
# dotfiles directories
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly RC_DIR=$(realpath -s "$SCRIPT_DIR/..")
readonly CONFIG_DIR=$(realpath -s "$SCRIPT_DIR/../../.config")
readonly RC_MZL_DIR="$CONFIG_DIR/mozilla"

# home directories to create
readonly PPW_ROOT="$REAL_USER_HOME/.config/pipewire/"
readonly MZL_ROOT="$REAL_USER_HOME/.mozilla/firefox"
readonly BIN_ROOT="$REAL_USER_HOME/bin"
readonly WRK_ROOT="$REAL_USER_HOME/work"
readonly SMR_ROOT="$REAL_USER_HOME/seminar"
readonly RND_ROOT="$REAL_USER_HOME/random"

add-gsettings-shortcut () (
    [[ $# -ne 3 ]] && return 2
    # $1 is the name
    # $2 is the command
    # $3 is the bind, in <Modifier>Key format
    
    custom_keybinds_enum="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | sed -e "s/@as//" | tr "'" "\"")"
    custom_keybinds_length="$(echo "$custom_keybinds_enum"  | jq ". | length")"
    
    keybind_version="custom$custom_keybinds_length"
    new_keybind_enumerator="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$keybind_version/"
    
    new_custom_keybinds_enum="$(echo "$custom_keybinds_enum" | jq -c ". += [\"$new_keybind_enumerator\"]" | tr '"' "'")"
    new_keybind_name=( "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$keybind_version/" "name" "$1" )
    new_keybind_command=( "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$keybind_version/" "command" "$2" )
    new_keybind_bind=( "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$keybind_version/" "binding" "$3" )
    
    gsettings set "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings" "$new_custom_keybinds_enum"
    gsettings set "${new_keybind_name[@]}"
    gsettings set "${new_keybind_command[@]}"
    gsettings set "${new_keybind_bind[@]}"
    
    #gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[<altered_list>]"
    #gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name '<newname>'
    #gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command '<newcommand>'
    #gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<key_combination>'
)

dnf-install () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-INSTALL----------------"
    while : ; do
        dnf install -y --best --allowerasing $@ && break
    done
    echo-success "Finished installing."
)

dnf-group-install-with-optional () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-GROUP-INSTALL----------------"
    for g in "$@"; do
        while :; do 
            dnf group install -y --best --allowerasing --with-optional "$g" && break
        done 
    done
    echo-success "Finished group-installing."
)

dnf-group-update () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-GROUP-UPDATE----------------"
    while :; do 
        dnf group update -y --best --allowerasing $@ && break
    done 
    echo-success "Finished group-updating."
)

dnf-update-refresh () (
    echo-status "-------------------DNF-UPDATE----------------"
    while : ; do
        dnf update -y 
        dnf upgrade -y --refresh && break
    done
    echo-success "Finished updating."
)

dnf-remove () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-REMOVE----------------"
    dnf remove -y --skip-broken $@
    echo-success "Finished removing."
)

flatpak-install () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    echo-status "-------------------FLATPAK-INSTALL-SYSTEM----------------"
    while : ; do
        su - "$REAL_USER" -c "flatpak install --system --noninteractive -y $@" && break
    done
    echo-success "Finished flatpak-installing."
)

change-ownership () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown "$REAL_USER" "$@"
    chmod 740 "$@"
)


change-ownership-recursive () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown -R "$REAL_USER" "$@"
    chmod -R 740 "$@"
)

change-group () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chgrp "$REAL_USER" "$@"
)

change-group-recursive () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chgrp -R "$REAL_USER" "$@"
)

create-default-locations () (
    # there should be a matching change-ownership-recursive after everything's done later
    #  since everything here will be owned by "root" 
    mkdir -p "$PPW_ROOT" "$MZL_ROOT" "$BIN_ROOT" "$WRK_ROOT" "$SMR_ROOT" "$RND_ROOT"
)

copy-dnf () (
    (cat <<-DNF_EOF 
[main]
gpgcheck=1
installonly_limit=5
clean_requirements_on_remove=True
best=False
deltarpm=False
skip_if_unavailable=True
max_parallel_downloads=10
metadata_expire=1
keepcache=true
DNF_EOF
    ) > "/etc/dnf/dnf.conf"
)

try-enabling-power-profiles-daemon () (
    systemctl enable power-profiles-daemon.service
    systemctl start power-profiles-daemon.service
    readonly PLACEHOLDER_COUNT=$(powerprofilesctl list | grep placeholder | wc -l)
    if [[ $PLACEHOLDER_COUNT -gt 1 ]]; then
        systemctl stop power-profiles-daemon.service
        systemctl mask power-profiles-daemon.service
    fi
)

copy-pipewire () (    
    ln -sf "$CONFIG_DIR/pipewire.conf" "$PPW_ROOT/pipewire.conf"
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
    echo "* - maxsyslogins 20" > "/etc/security/limits.d/90-maxsyslogins.conf"
)

create-convenience-sudoers () (
    readonly fname="/etc/sudoers.d/convenience-defaults"
    
    echo "Defaults timestamp_timeout=120, pwfeedback" > "$fname"
    chmod 440 "$fname" # 440 is the default rights of /etc/sudoers file, so we're copying the rights just in case (even though visudo -f /etc/sudoers.d/test creates the file with 640)
)

create-gdm-dconf-profile () (
    readonly fname="/etc/dconf/profile/gdm"

    (cat <<GDM_END
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDM_END
    ) > "$fname"
    
    chmod 644 "$fname"
)

create-gdm-dconf-db () (
    readonly fname="/etc/dconf/db/gdm.d/01-generic"
    
    (cat <<-GDM_END
[org/gnome/desktop/interface] 
clock-format='24h'
clock-show-date=true
clock-show-seconds=true
clock-show-weekday=true
font-antialiasing='rgba'
font-hinting='full'
show-battery-percentage=true

[org/gnome/desktop/peripherals/keyboard] 
numlock-state=false
remember-numlock-state=false
repeat=true
repeat-interval=25

[org/gnome/desktop/peripherals/mouse]
double-click=250
middle-click-emulation=false
natural-scroll=false
speed=-0.2

[org/gnome/desktop/peripherals/touchpad]
disable-while-typing=true
GDM_END
    ) > "$fname"
    
    chmod 644 "$fname"
)

create-private-bashrc () (
    touch "$REAL_USER_HOME/.bashrc-private"
)

create-private-gitconfig () (
    touch "$REAL_USER_HOME/.gitconfig-github"
    touch "$REAL_USER_HOME/.gitconfig-gitlab"
    touch "$REAL_USER_HOME/.gitconfig-gnome"
)

copy-rc-files () (
    ln -sf "$RC_DIR/.bashrc" "$REAL_USER_HOME/.bashrc"
    ln -sf "$RC_DIR/.nanorc" "$REAL_USER_HOME/.nanorc"
    ln -sf "$CONFIG_DIR/.gitconfig" "$REAL_USER_HOME/.gitconfig"
)

copy-ff-rc-files () (
    #https://askubuntu.com/questions/239543/get-the-default-firefox-profile-directory-from-bash
    if [[ $(grep '\[Profile[^0]\]' "$MZL_ROOT/profiles.ini") ]]; then
        readonly PROFPATH=$(grep -E '^\[Profile|^Path|^Default' "$MZL_ROOT/profiles.ini" | grep '^Path' | cut -c6- | tr " " "\n")
    else
        readonly PROFPATH=$(grep 'Path=' "$MZL_ROOT/profiles.ini" | sed 's/^Path=//')
    fi

    for MZL_PROF_DIR in $PROFPATH; do
        MZL_PROF_DIR_ABSOLUTE="$MZL_ROOT/$MZL_PROF_DIR"

        # preference rc
        ln -sf "$RC_MZL_DIR/user.js" "$MZL_PROF_DIR_ABSOLUTE/user.js"
    done
)

#######################################################################################################
# NVIDIA DRIVER SPECIFIC FUNCTIONS

# USEFUL COMMAND: dnf whatprovides COMMAND
#  e.g. dnf whatprovides nvidia-smi

# TODO match-model-to-akmod
# this is the exhaustive list for each legacy driver & their support
# https://www.nvidia.com/en-us/drivers/unix/legacy-gpu/
# it's wise to declare this huge list at the end of this file, since this is meant to be sourced
# rather than executed directly
#  nvidia-settings
#  akmod-nvidia
#  xorg-x11-drv-nvidia
#  xorg-x11-drv-nvidia-cuda
#  xorg-x11-drv-nvidia-cuda-libs
#  xorg-x11-drv-nvidia-libs
#
#  nvidia-settings-470xx
#  akmod-nvidia-470xx
#  xorg-x11-drv-nvidia-470xx
#  xorg-x11-drv-nvidia-470xx-cuda
#  xorg-x11-drv-nvidia-470xx-cuda-libs
#  xorg-x11-drv-nvidia-470xx-libs
#
#  nvidia-settings-390xx
#  akmod-nvidia-390xx
#  xorg-x11-drv-nvidia-390xx
#  xorg-x11-drv-nvidia-390xx-cuda
#  xorg-x11-drv-nvidia-390xx-cuda-libs
#  xorg-x11-drv-nvidia-390xx-libs
#
#  akmod-nvidia-340xx
#  xorg-x11-drv-nvidia-340xx
#  xorg-x11-drv-nvidia-340xx-cuda
#  xorg-x11-drv-nvidia-340xx-libs

# TODO get-gpu-model -> should support anything "mainstream" that the above akmods support 

# TODO is-nvidia-gpu

#######################################################################################################
# HELPERS

echo-important () (
    tput setaf 3 # yellow
    tput bold
    echo "[IMPORTANT] [$(date +"%H:%M:%S")] $@"
    tput sgr0
)

echo-success () (
    tput setaf 2 # green 
    tput bold
    echo "[SUCCESS] [$(date +"%H:%M:%S")] $@"
    tput sgr0
)

echo-status () (
    # echo for status updates
    tput setaf 4 # blue
    echo "[STATUS] [$(date +"%H:%M:%S")] $@"
    tput sgr0
)

echo-unexpected () (
    tput setaf 1
    tput bold
    echo "[UNEXPECTED] [$(date +"%H:%M:%S")] $@"
    tput sgr0
)

echo-debug () (
    [[ -z "${DEBUG_SETUP_ON}" ]] && return
    tput setaf 5
    echo "[DEBUG] [$(date +"%H:%M:%S")] $@"
    tput sgr0
)

# do NOT use this for anything else other than echoing from a call whose stdout is meant to be caught!
# use echo-debug for debug information, and echo-important and friends for everything else 
# https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
_echo-stderr () (
    echo "$@" 1>&2
)

ask-user () (
    while : ; do
        read -p "$* [Y/n]: " -r
        _echo-stderr ""
        [[ $REPLY =~ ^[Yy]$ ]] && return 0
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
        _echo-stderr "Invalid reply \"$REPLY\", please answer with Y/y for Yes, or N/n for No."
    done
)

ask-user-multiple-choice () (
    # $1 onwards should be the options users have in detail
    # output is in stdout, so we need to capture that;
    #  unfortunately, (one of) the only sane way(s) to still output 
    #  while capturing stdout, is to output to stderr
    range="[0-$(($#-1))]"
    while : ; do
        i=0
        for option in "$@"; do
            _echo-stderr "$((i++)). $option" 
        done
        read -p "Choice $range: " -r
        _echo-stderr ""
        if [[ $REPLY =~ ^[0-9][0-9]*$ && $REPLY -lt $# ]]; then
            echo "$REPLY"
            return
        fi
        _echo-stderr "Invalid reply > $REPLY, please answer in the range of $range."
    done
)

is-root () (
     [[ $(id -u) = 0 ]] && return 0
     return 1
)

is-gnome-session () (
    [[ $XDG_CURRENT_DESKTOP == "GNOME" ]] && return 0
    return 1
)

is-xcinnamon-session () (
    [[ $XDG_CURRENT_DESKTOP == "X-Cinnamon" ]] && return 0
    return 1
)

is-btrfs-rootfs () (
    [[ "btrfs" == $ROOT_FS ]] && return 0
    return 1
)

is-btrfs-homefs () (
    [[ "btrfs" == $REAL_USER_HOME_FS ]] && return 0
    return 1
)

is-uefi () (
    [[ "$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)" == "UEFI" ]] && return 0
    return 1
)

is-desktop-type () (
    [[ "$(dmidecode --string chassis-type)" == "Desktop" ]] && return 0
    return 1
)

is-mobile-type () (
    readonly CHASSIS_TYPE="$(dmidecode --string chassis-type)"
    [[ $CHASSIS_TYPE == "Notebook" || $CHASSIS_TYPE == "Tablet" || $CHASSIS_TYPE == "Convertible" ]] && return 0
    return 1
)
