#!/bin/bash

# https://askubuntu.com/questions/425754/how-do-i-run-a-sudo-command-inside-a-script

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
    echo "The script need to be run as root." >&2
    exit 1
fi

if ! ping -q -c 1 -W 1 google.com >/dev/null; then
    echo "Network connection was not detected."
    echo "This script needs network connectivity to continue."
    read -p "Are you sure you want to continue?[Y/n] " -n 1 -r
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

# fs thingies
ROOT_FS=$(stat -f --format=%T /)
REAL_USER_HOME_FS=$(stat -f --format=%T $REAL_USER_HOME)
SCRIPT_DIR_FS=$(stat -f --format=%T $SCRIPT_DIR)

DISTRIBUTION_NAME="nobara"
INSTALLABLE_PACKAGES="\
neofetch \
meson \
java-latest-openjdk \
java-latest-openjdk-devel \
firefox \
chromium \
fedora-chromium-config \
git \
alacritty \
gedit \
gedit-plugin* \
gedit-color-schemes \
gimp \
obs-studio \
libreoffice \
protonup-qt \
piper \
qbittorrent \
sqlitebrowser \
gydl \
handbrake \
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
"

INSTALLABLE_FLATPAKS="\
spotify \
com.discordapp.Discord \
joplin \
teamspeak \
skype \
zoom \
openra \
"

INSTALLABLE_EXTENSIONS="\
gnome-shell-extension-dash-to-panel \
gnome-shell-extension-pop-shell \
gnome-shell-extension-pop-shell-shortcut-overrides \
gnome-shell-extension-places-menu \
gnome-shell-extension-appindicator \
gnome-shell-extension-sound-output-device-chooser \
gnome-shell-extension-freon \
"

INSTALLABLE_IDE_FLATPAKS="\
org.gnome.Builder \
ar.xjuan.Cambalache \
org.gnome.Glade \
cc.arduino.IDE2 \
com.vscodium.codium \
"

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
chmod 700 /home/*
sudo systemctl enable fstrim.timer

echo "-------------------UPDATING----------------"
#dnf update -y 2> /dev/null

echo "-------------------INSTALLING---------------- $INSTALLABLE_PACKAGES" | tr " " "\n"
#dnf install -y $INSTALLABLE_PACKAGES 2> /dev/null

case "btrfs" in
    "$ROOT_FS" | "$REAL_USER_HOME_FS" |  "$SCRIPT_DIR_FS")
        echo "found BTRFS, installing btrfs-assistant"
#        dnf install -y btrfs-assistant > /dev/null
        ;;
    *)
        echo "BTRFS not found; continuing as usual..."
        ;;
esac

echo "-------------------INSTALLING----------------" | tr " " "\n"
dnf group info "Development Tools" 2> /dev/null
read -p "Are you sure you want to install Development Tools?[Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo ""
#    dnf groupinstall -y "Development Tools" 2> /dev/null
fi

echo "Switching to $REAL_USER to install flatpaks"
echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS" | tr " " "\n"
#su - $REAL_USER -c "flatpak install --user -y $INSTALLABLE_FLATPAKS"
echo "Continuing as $(whoami)"

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS" | tr " " "\n"
read -p "Are you sure you want to install Community IDEs?[Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo ""
#    su - $REAL_USER -c "flatpak install --user -y $INSTALLABLE_IDE_FLATPAKS"
fi

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTENSIONS" | tr " " "\n"
read -p "Are you sure you want to install extensions?[Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo ""
#    dnf install -y $INSTALLABLE_EXTENSIONS 2> /dev/null
fi


echo "---------------------------------------------"
echo "For automatic management of Jetbrains IDEs,"
echo "please install Toolbox. https://www.jetbrains.com/toolbox-app/"
echo "Recommended IDEs are:"
echo "- PyCharm Ultimate"
echo "- IntelliJ Idea Ultimate"
echo "- CLion"
echo "- Android Studio"
echo "---------------------------------------------"
echo "---------------------------------------------"
echo "Make sure to download & activate" 
echo "- Night Theme Switcher"
echo "  https://extensions.gnome.org/extension/2236/night-theme-switcher/"
echo "---------------------------------------------"
echo "---------------------------------------------"
echo "Please make sure to add a mount point for permanently mounted partitions."
echo "Standard fstab USER mount arguments:"
echo "rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "Standard fstab ROOT mount arguments:"
echo "nouser,nosuid,nodev,nofail,x-gvfs-show,x-udisks-auth"
echo "---------------------------------------------"


systemctl restart NetworkManager
hostnamectl hostname "$DISTRIBUTION_NAME"

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "Couldn't updatedb, retrying with absolute path"
    /usr/sbin/updatedb
fi

