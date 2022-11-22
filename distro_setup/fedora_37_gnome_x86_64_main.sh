#!/bin/bash

# https://askubuntu.com/questions/425754/how-do-i-run-a-sudo-command-inside-a-script

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
    echo "The script needs to be run as root." >&2
    exit 1
fi

if ! ping -q -c 1 -W 1 google.com > /dev/null; then
    echo "Network connection was not detected."
    echo "This script needs network connectivity to continue."
    while : ; do
        read -p "Are you sure you want to continue?[Y/n] " -n 1 -r
        ! [[ $REPLY =~ ^[YyNn]$ ]] || break
    done 
    echo ""
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi


# Define colors
LIGHTGRAY="\033[0;37m"
WHITE="\033[1;37m"
BLACK="\033[0;30m"
DARKGRAY="\033[1;30m"
RED="\033[0;31m"
LIGHTRED="\033[1;31m"
GREEN="\033[0;32m"
LIGHTGREEN="\033[1;32m"
BROWN="\033[0;33m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
LIGHTBLUE="\033[1;34m"
MAGENTA="\033[0;35m"
LIGHTMAGENTA="\033[1;35m"
CYAN="\033[0;36m"
LIGHTCYAN="\033[1;36m"
NOCOLOR="\033[0m"


if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

# https://unix.stackexchange.com/questions/247576/how-to-get-home-given-user
REAL_USER_HOME=$(eval echo "~$REAL_USER")
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RC_DIR="$SCRIPT_DIR/../rc"
RC_MZL_DIR="$SCRIPT_DIR/../firefox"

# fs thingies
ROOT_FS=$(stat -f --format=%T /)
REAL_USER_HOME_FS=$(stat -f --format=%T $REAL_USER_HOME)
SCRIPT_DIR_FS=$(stat -f --format=%T $SCRIPT_DIR)

DISTRIBUTION_NAME="fedora"

INSTALLABLE_PACKAGES="\
neofetch \
onefetch \
meson \
curl \
java-latest-openjdk \
java-latest-openjdk-devel \
firefox \
chromium \
fedora-chromium-config \
git \
gimp \
libreoffice \
piper \
qbittorrent \
sqlitebrowser \
gydl \
lm_sensors \
tldr \
virt-manager \
libvirt-devel \
virt-top \
libguestfs-tools \
guestfs-tools \
bridge-utils \
libvirt \
virt-install \
qemu-kvm \
steam \
pinta \
qt5-qtbase \
flatpak \
openvpn \
plocate \
gnome-system-monitor \
adwaita-qt* \
"

INSTALLABLE_FLATPAKS="\
com.spotify.Client \
com.discordapp.Discord \
com.teamspeak.TeamSpeak \
com.raggesilver.BlackBox \
io.github.Foldex.AdwSteamGtk \
net.davidotek.pupgui2 \
fr.handbrake.ghb \
net.cozic.joplin_desktop \
com.teamspeak.TeamSpeak \
com.skype.Client \
us.zoom.Zoom \
net.openra.OpenRA \
com.obsproject.Studio \
com.github.Matoking.protontricks \
com.obsproject.Studio.Plugin.Gstreamer \
com.obsproject.Studio.Plugin.InputOverlay \
com.obsproject.Studio.Plugin.MoveTransition \
com.obsproject.Studio.Plugin.NVFBC \
com.obsproject.Studio.Plugin.OBSVkCapture \
com.obsproject.Studio.Plugin.ScaleToSound \
com.obsproject.Studio.Plugin.SceneSwitcher \
com.obsproject.Studio.Plugin.WebSocket \
com.obsproject.Studio.Plugin.waveform \
"

INSTALLABLE_EXTENSIONS="\
gnome-shell-extension-pop-shell \
gnome-shell-extension-pop-shell-shortcut-overrides \
gnome-shell-extension-places-menu \
gnome-shell-extension-appindicator \
gnome-shell-extension-sound-output-device-chooser \
gnome-shell-extension-freon \
gnome-shell-extension-lockkeys \
gnome-shell-extension-dash-to-panel \
"

INSTALLABLE_IDE_FLATPAKS="\
org.gnome.Builder \
ar.xjuan.Cambalache \
cc.arduino.IDE2 \
com.vscodium.codium \
"

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
chmod 700 "$REAL_USER_HOME"
chown "$REAL_USER" "$REAL_USER_HOME"
systemctl enable fstrim.timer

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak remote-add --if-not-exists appcenter https://flatpak.elementary.io/repo.flatpakrepo
dnf copr enable -y astrawan/gnome-shell-extensions 
dnf copr enable -y varlad/onefetch

#######################################################################################################

echo "-------------------UPDATING----------------"
while : ; do
    dnf update -y --refresh && dnf distro-sync -y --refresh
    dnf update -y 
    [[ $? != 0 ]] || break
done
echo "Finished updating system."

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_PACKAGES" | tr " " "\n"
while : ; do
    dnf install -y $INSTALLABLE_PACKAGES 
    [[ $? != 0 ]] || break
done

case "btrfs" in
    "$ROOT_FS" | "$REAL_USER_HOME_FS" |  "$SCRIPT_DIR_FS")
        echo "found BTRFS, installing btrfs-assistant"
        dnf install -y btrfs-assistant
        echo "finished installing btrfs-assistant"
        ;;
    *)
        echo "BTRFS not found; continuing as usual..."
        ;;
esac

echo "Switching to $REAL_USER to install flatpaks"
echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS" | tr " " "\n"
su - $REAL_USER -c "flatpak install -y $INSTALLABLE_FLATPAKS"
echo "Continuing as $(whoami)"

#######################################################################################################

echo "-------------------INSTALLING----------------" | tr " " "\n"
dnf group info "Development Tools"
while : ; do
    read -p "Are you sure you want to install Development Tools?[Y/n] " -n 1 -r
    ! [[ $REPLY =~ ^[YyNn]$ ]] || break
done 
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    while : ; do
        dnf groupinstall -y "Development Tools"     
        [[ $? != 0 ]] || break
    done
    echo "Finished installing Development Tools."
fi

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install Community IDEs & Jetbrains Toolbox?[Y/n] " -n 1 -r
    ! [[ $REPLY =~ ^[YyNn]$ ]] || break
done 

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    su - $REAL_USER -c "flatpak install -y $INSTALLABLE_IDE_FLATPAKS"
    echo "Finished installing IDEs."
    
    echo "-------------------INSTALLING JETBRAINS TOOLBOX----------------"
    mkdir -p "$REAL_USER_HOME/cloned"
    chown -R "$REAL_USER" "$REAL_USER_HOME/cloned"
    curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
    echo "Finished installing toolbox."
fi

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTENSIONS" | tr " " "\n"
while : ; do
    read -p "Do you want to install extensions?[Y/n] " -n 1 -r
    ! [[ $REPLY =~ ^[YyNn]$ ]] || break
done 
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    while : ; do
        dnf install -y $INSTALLABLE_EXTENSIONS 
        [[ $? != 0 ]] || break  
    done
    
    echo "Finished installing extensions."
fi

#######################################################################################################

echo "-------------------INSTALLING RC FILES----------------"

ln -sf "$RC_DIR/.vimrc" "$REAL_USER_HOME/.vimrc"
ln -sf "$RC_DIR/.bashrc" "$REAL_USER_HOME/.bashrc" 
ln -sf "$RC_DIR/.nanorc" "$REAL_USER_HOME/.nanorc"
ln -sf "$RC_DIR/.gitconfig" "$REAL_USER_HOME/.gitconfig"

#https://askubuntu.com/questions/239543/get-the-default-firefox-profile-directory-from-bash
MZL_ROOT="$REAL_USER_HOME/.mozilla/firefox"
if [[ $(grep '\[Profile[^0]\]' "$MZL_ROOT/profiles.ini") ]];then 
    PROFPATH=$(grep -E '^\[Profile|^Path|^Default' "$MZL_ROOT/profiles.ini" | grep '^Path' | cut -c6- | tr " " "\n")
else 
    PROFPATH=$(grep 'Path=' "$MZL_ROOT/profiles.ini" | sed 's/^Path=//')
fi

for MZL_PROF_DIR in $PROFPATH; do
    MZL_PROF_DIR_ABSOLUTE="$MZL_ROOT/$MZL_PROF_DIR"
    MZL_PROF_CHROME_DIR_ABSOLUTE="$MZL_PROF_DIR_ABSOLUTE/chrome"
    mkdir -p "$MZL_PROF_CHROME_DIR_ABSOLUTE"
    ln -sf "$RC_MZL_DIR/userChrome.css" "$MZL_PROF_CHROME_DIR_ABSOLUTE/userChrome.css"
    ln -sf "$RC_MZL_DIR/userContent.css" "$MZL_PROF_CHROME_DIR_ABSOLUTE/userContent.css"
    ln -sf "$RC_MZL_DIR/mono-firefox-theme" "$MZL_PROF_CHROME_DIR_ABSOLUTE/mono-firefox-theme"
done

echo "Finished installing rc files."

#######################################################################################################

mkdir -p "$REAL_USER_HOME/.ssh"
chown -R "$REAL_USER" "$REAL_USER_HOME/.ssh"
ssh-keygen -t rsa -b 4096 -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$REAL_USER_HOME/.ssh/id_rsa" -P "" && cat "$REAL_USER_HOME/.ssh/id_rsa.pub"
chmod 700 "$REAL_USER_HOME/.ssh"

#######################################################################################################

systemctl restart NetworkManager
hostnamectl hostname "$DISTRIBUTION_NAME"

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "Couldn't updatedb, retrying with absolute path"
    /usr/sbin/updatedb
fi

#######################################################################################################

echo "--------------------------- IDE ---------------------------"
echo "Recommended Jetbrains IDEs are:"
echo "- PyCharm Ultimate"
echo "- IntelliJ Idea Ultimate"
echo "- CLion"
echo "- Android Studio"
echo "--------------------------- THEMING ---------------------------"
echo "Please install 'night theme switcher' using the Gnome Extensions website."
echo "https://extensions.gnome.org/extension/2236/night-theme-switcher/"
echo ""
echo "Please run AdwSteamGtk to convert steam to the Adwaita theme."
echo ""
echo "Please go to firefox about:config and enable toolkit.legacyUserProfileCustomizations.stylesheets to true."
echo "--------------------------- VISUDO ---------------------------"
echo "Please sudo visudo and add:"
echo "  Defaults env_reset, timestamp_timeout=120, pwfeedback"
echo "--------------------------- FSTAB ---------------------------"
echo "Remember to add a permanent mount point for permanently mounted partitions."
echo "Standard fstab USER mount arguments:"
echo "  rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "Standard fstab ROOT mount arguments:"
echo "  nouser,nosuid,nodev,nofail,x-gvfs-show,x-udisks-auth"
echo "--------------------------- SWAP ---------------------------"
echo "If using ext4, create a swapfile with these commands:"
echo "16GB:"
echo "  sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo "32GB:"
echo "  sudo fallocate -l 32G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo "64GB:"
echo "  sudo fallocate -l 64G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo "128GB:"
echo "  sudo fallocate -l 128G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo ""
echo "It's possible this swapfile won't persist after reboots; confirm with:"
echo "  sudo swapon --show"
echo "If this is the case, make permanent by appending this line in /etc/fstab:"
echo "  /swapfile swap swap defaults 0 0"
echo "------------------------------------------------------"
