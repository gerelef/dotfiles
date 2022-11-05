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

DISTRIBUTION_NAME="nobara"
INSTALLABLE_PACKAGES="\
perl \
neofetch \
meson \
curl \
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

GDBUS_NIGHT_THEME_SWITCHER_ID="2236"

INSTALLABLE_IDE_FLATPAKS="\
org.gnome.Builder \
ar.xjuan.Cambalache \
org.gnome.Glade \
cc.arduino.IDE2 \
com.vscodium.codium \
"

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
chmod 700 "$REAL_USER_HOME"
chown "$REAL_USER" "$REAL_USER_HOME"
sudo systemctl enable fstrim.timer

echo "-------------------UPDATING----------------"
while : ; do
    dnf update fedora-repos nobara-repos --refresh && sudo dnf update --refresh && sudo dnf distro-sync --refresh
    dnf update -y 
    [[ $? != 0 ]] || break
done
echo "Finished updating system."

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

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install Community IDEs?[Y/n] " -n 1 -r
    ! [[ $REPLY =~ ^[YyNn]$ ]] || break
done 

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    su - $REAL_USER -c "flatpak install -y $INSTALLABLE_IDE_FLATPAKS"
    echo "Finished installing IDEs."
fi

echo "-------------------INSTALLING JETBRAINS TOOLBOX----------------"
mkdir -p "$REAL_USER_HOME/cloned"
chown -R "$REAL_USER" "$REAL_USER_HOME/cloned"
curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
echo "Finished installing toolbox."

echo "Switching to $REAL_USER to install flatpaks"
echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS" | tr " " "\n"
su - $REAL_USER -c "flatpak install -y $INSTALLABLE_FLATPAKS"
echo "Continuing as $(whoami)"

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTENSIONS" | tr " " "\n"
echo "& night theme switcher using gnome-shell-extension-installer"
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
    
    wget -O "gnome-shell-extension-installer" "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
    chmod 551 "gnome-shell-extension-installer"
    mv "gnome-shell-extension-installer" "/usr/bin/"
    
    echo "Finished installing extensions."
fi

echo "-------------------INSTALLING RC FILES----------------"

ln -s "$RC_DIR/.vimrc" "$REAL_USER_HOME/.vimrc"
ln -s "$RC_DIR/.bashrc" "$REAL_USER_HOME/.bashrc" 
ln -s "$RC_DIR/.nanorc" "$REAL_USER_HOME/.nanorc"
ln -s "$RC_DIR/.gitconfig" "$REAL_USER_HOME/.gitconfig"

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
    ln -s "$RC_MZL_DIR/userChrome.css" "$MZL_PROF_CHROME_DIR_ABSOLUTE/userChrome.css"
done

echo "Finished installing rc files."

mkdir -p "$REAL_USER_HOME/.ssh"
chown -R "$REAL_USER" "$REAL_USER_HOME/.ssh"
ssh-keygen -t rsa -b 4096 -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$REAL_USER_HOME/.ssh/id_rsa" -P "" && cat "$REAL_USER_HOME/.ssh/id_rsa.pub"
chmod 700 "$REAL_USER_HOME/.ssh"

systemctl restart NetworkManager
hostnamectl hostname "$DISTRIBUTION_NAME"

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "Couldn't updatedb, retrying with absolute path"
    /usr/sbin/updatedb
fi

echo "---------------------------------------------"
echo "Jetbrains has been automatically installed."
echo "Recommended IDEs are:"
echo "- PyCharm Ultimate"
echo "- IntelliJ Idea Ultimate"
echo "- CLion"
echo "- Android Studio"
echo "---------------------------------------------"
echo "Please run gnome-shell-extension-installer $GDBUS_NIGHT_THEME_SWITCHER_ID to install the last available extension."
echo "---------------------------------------------"
echo "Please sudo visudo and add:"
echo "  Defaults env_reset, timestamp_timeout=120, pwfeedback"
echo "---------------------------------------------"
echo "Please remember to add a permanent mount point for permanently mounted partitions."
echo "Standard fstab USER mount arguments:"
echo "  rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "Standard fstab ROOT mount arguments:"
echo "  nouser,nosuid,nodev,nofail,x-gvfs-show,x-udisks-auth"
echo "---------------------------------------------"
