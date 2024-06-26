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

dnf-group-install () (
    echo-status "-------------------DNF-GROUP-INSTALL----------------"
    for g in "$@"; do
        while :; do 
            dnf group install -y --best --allowerasing "$g" && break
        done 
    done
    echo-success "Finished group-installing."
)

dnf-group-install-with-optional () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-GROUP-INSTALL-WITH-OPTIONAL----------------"
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

dnf5-remove () (
    [[ $# -eq 0 ]] && return 2
    
    echo-status "-------------------DNF-REMOVE----------------"
    dnf remove -y $@
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

configure-residual-permissions () (
    echo-status "-------------------CHANGING ROOT OWNERSHIP AND GROUPS IN HOME----------------"
    chown "$REAL_USER" "$REAL_USER_HOME"
    chgrp "$REAL_USER" "$REAL_USER_HOME"
    
    # everything in home should be owned by the user and in the user's group
    # this filter finds which f
    find "$REAL_USER_HOME" -user root -print0 2> /dev/null | while read -d $'\0' file; do
        echo-debug "chown chgrp $file"
        
        chown "$REAL_USER" "$file"
        chgrp "$REAL_USER" "$file"
    done
    
    echo-success "Done."
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
    sleep 10  # sleep in order for the service to spin up
    readonly PLACEHOLDER_COUNT=$(powerprofilesctl list | grep placeholder | wc -l)
    if [[ $PLACEHOLDER_COUNT -gt 1 ]]; then
        systemctl stop power-profiles-daemon.service
        systemctl mask power-profiles-daemon.service
    fi
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

# USEFUL COMMAND: dnf whatprovides COMMAND
#  e.g. dnf whatprovides nvidia-smi

#######################################################################################################
# HELPERS

echo-important () (
    tput setaf 3 # yellow
    tput bold
    echo "[IMPORTANT] [$(date +"%H:%M:%S")] $@"
    tput sgr0
    
    echo "[IMPORTANT] $@" | systemd-cat --identifier="setup.sh" --priority="notice"
)

echo-success () (
    tput setaf 2 # green 
    tput bold
    echo "[SUCCESS] [$(date +"%H:%M:%S")] $@"
    tput sgr0
    
    echo "[SUCCESS] $@" | systemd-cat --identifier="setup.sh" --priority="notice"
)

echo-status () (
    # echo for status updates
    tput setaf 6 # cyan
    echo "[STATUS] [$(date +"%H:%M:%S")] $@"
    tput sgr0
    
    echo "[STATUS] $@" | systemd-cat --identifier="setup.sh" --priority="notice"
)

echo-unexpected () (
    tput setaf 1 # red
    tput bold
    echo "[UNEXPECTED] [$(date +"%H:%M:%S")] $@"
    tput sgr0
    
    echo "[UNEXPECTED] $@" | systemd-cat --identifier="setup.sh" --priority="err"
)

echo-debug () (
    [[ -z "${DEBUG_SETUP_ON}" ]] && return
    tput setaf 5
    echo "[DEBUG] [$(date +"%H:%M:%S")] $@"
    tput sgr0
    
    echo "[DEBUG] $@" | systemd-cat --identifier="setup.sh" --priority="notice" 
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
        [[ $REPLY =~ ^[Yy]$ ]] && return 0
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
        _echo-stderr ""
        _echo-stderr "Invalid reply \"$REPLY\", please answer with Y/y for Yes, or N/n for No."
    done
)

ask-user-multiple-choice () (
    # $1 onwards should be the options users have in detail
    # output is in stdout, so we need to capture that;
    #  unfortunately, (one of) the only sane way(s) to still output 
    #  while capturing stdout, is to output to stderr
    readonly args=($@)
    readonly range="[0-$(($#-1))]"
    
    while : ; do
        i=0
        for option in "$@"; do
            _echo-stderr "$((i++)). $option" 
        done
        read -p "Choice $range: " -r
        if [[ $REPLY =~ ^[0-9][0-9]*$ && $REPLY -lt $# ]]; then
            _echo-stderr ""
            if ! ask-user "Are you sure you want to pick \"${args[$REPLY]}\"?"; then continue; fi
            
            echo "$REPLY"
            return
        fi
        _echo-stderr ""
        _echo-stderr "Invalid reply > $REPLY, please answer in the range of $range."
    done
)

is-root () (
    echo-debug "is-root $(id -u) (0 is root)"
    [[ $(id -u) = 0 ]] && return 0
    return 1
)

is-gnome-session () (
    echo-debug "is-gnome-session $XDG_CURRENT_DESKTOP"
    [[ $XDG_CURRENT_DESKTOP == "GNOME" ]] && return 0
    return 1
)

is-xcinnamon-session () (
    echo-debug "is-xcinnamon-session $XDG_CURRENT_DESKTOP"
    [[ $XDG_CURRENT_DESKTOP == "X-Cinnamon" ]] && return 0
    return 1
)

is-btrfs-rootfs () (
    echo-debug "is-btrfs-homefs $ROOT_FS"
    [[ "btrfs" == $ROOT_FS ]] && return 0
    return 1
)

is-btrfs-homefs () (
    echo-debug "is-btrfs-homefs $REAL_USER_HOME_FS"
    [[ "btrfs" == $REAL_USER_HOME_FS ]] && return 0
    return 1
)

is-uefi () (
    echo-debug "is-uefi $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)"
    [[ "$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)" == "UEFI" ]] && return 0
    return 1
)

is-desktop-type () (
    echo-debug "is-desktop-type $(dmidecode --string chassis-type)"
    [[ "$(dmidecode --string chassis-type)" == "Desktop" ]] && return 0
    return 1
)

is-mobile-type () (
    echo-debug "is-mobile-type $(dmidecode --string chassis-type)"
    readonly CHASSIS_TYPE="$(dmidecode --string chassis-type)"
    [[ $CHASSIS_TYPE == "Notebook" || $CHASSIS_TYPE == "Tablet" || $CHASSIS_TYPE == "Convertible" ]] && return 0
    return 1
)

is-virtual-machine () (
    echo-debug "is-virtual-machine $(systemd-detect-virt)"
    [[ $(systemd-detect-virt) != "none" ]] && return 0
    return 1
)

is-nvidia-gpu () (
    (lspci | grep -i vga | grep NVIDIA) && return 0
    return 1
)

get-nvidia-gpu-model () (
    readonly mdl="$(lspci | grep -i vga | grep NVIDIA | grep -E --only-matching "(\[.+\])" | tr -d '[]')"
    echo "$mdl"
)

is-service-running () {
    echo-debug "is-service-running $1"
    [[ $# != 1 ]] && exit 1
    systemctl is-active --quiet "$1" && return 0
    return 1
}

login-as-service-user () (
    # username and command must be given
    echo-debug "login-as-systemd-service-user $1 $2"
    [[ $# != 2 ]] && exit 1
    machinectl shell "$1@" $(whereis bash | awk '{ printf $2 }') -c "$2"
)
