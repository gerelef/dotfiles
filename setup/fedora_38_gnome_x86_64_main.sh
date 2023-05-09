#!/usr/bin/env bash

readonly DIR=$(dirname -- "$BASH_SOURCE")

source "$DIR/common-utils.sh"

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
    echo "The script needs to be run as root." >&2
    exit 1
fi

if ! ping -q -c 1 -W 1 google.com > /dev/null; then
    echo "Network connection was not detected."
    echo "This script needs network connectivity to continue."
    exit 1
fi

if [ $SUDO_USER ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

# https://unix.stackexchange.com/questions/247576/how-to-get-home-given-user
readonly REAL_USER_HOME=$(eval echo "~$REAL_USER")
# dotfiles directories
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly RC_DIR="$SCRIPT_DIR/../rc"
readonly RC_MZL_DIR="$SCRIPT_DIR/../firefox"

# home directories to create
readonly CLONED_ROOT="$REAL_USER_HOME/cloned"
readonly MZL_ROOT="$REAL_USER_HOME/.mozilla/firefox"
readonly SSH_ROOT="$REAL_USER_HOME/.ssh"
readonly BIN_ROOT="$REAL_USER_HOME/bin"
readonly WRK_ROOT="$REAL_USER_HOME/work"
readonly SMR_ROOT="$REAL_USER_HOME/seminar"
readonly RND_ROOT="$REAL_USER_HOME/random"

# there should be a matching change-ownership-recursive after everything's done in the script 
mkdir -p "$CLONED_ROOT" "$MZL_ROOT" "$SSH_ROOT" "$BIN_ROOT" "$WRK_ROOT" "$SMR_ROOT" "$RND_ROOT" 

# fs thingies
readonly ROOT_FS=$(stat -f --format=%T /)
readonly REAL_USER_HOME_FS=$(stat -f --format=%T "$REAL_USER_HOME")
readonly SCRIPT_DIR_FS=$(stat -f --format=%T "$SCRIPT_DIR")

readonly DISTRIBUTION_NAME="fedora"

readonly INSTALLABLE_PACKAGES="\
flatpak \
adw-gtk3 \
git \
meson \
curl \
java-latest-openjdk \
java-latest-openjdk-devel \
firefox \
chromium \
fedora-chromium-config \
gimp \
krita \
libreoffice \
qbittorrent \
sqlitebrowser \
gnome-system-monitor \
piper \
qt5-qtbase \
adwaita-qt5 \
adwaita-qt6 \
setroubleshoot \
setroubleshoot-plugins \
vulkan \
swtpm \
swtpm-tools \
virt-manager \
libvirt-devel \
virt-top \
libguestfs-tools \
guestfs-tools \
bridge-utils \
libvirt \
virt-install \
qemu-kvm \
openvpn \
pulseeffects \
"

readonly INSTALLABLE_CODECS="\
gstreamer1-plugins-* \
gstreamer1-plugin-openh264 \
gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel \
"

readonly UNINSTALLABLE_BLOAT="\
rhythmbox* \
totem \
gnome-tour \
gnome-terminal \
gnome-terminal-* \
gnome-boxes* \
gnome-calculator* \
gnome-calendar* \
gnome-color-manager* \
gnome-contacts* \
gnome-maps* \
"

readonly INSTALLABLE_FLATPAKS="\
org.gtk.Gtk3theme.adw-gtk3 \
org.gtk.Gtk3theme.adw-gtk3-dark \
org.videolan.VLC \
io.gitlab.theevilskeleton.Upscaler \
com.raggesilver.BlackBox \
com.spotify.Client \
net.cozic.joplin_desktop \
com.skype.Client \
us.zoom.Zoom \
com.github.Matoking.protontricks \
net.openra.OpenRA \
com.github.tchx84.Flatseal \
"

readonly INSTALLABLE_OBS_STUDIO="\
com.obsproject.Studio \
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

readonly INSTALLABLE_EXTENSIONS="\
xprop \
gnome-shell-extension-pop-shell \
gnome-shell-extension-pop-shell-shortcut-overrides \
gnome-shell-extension-places-menu \
"

readonly INSTALLABLE_BTRFS_TOOLS="\
btrfs-assistant \
timeshift \
"

readonly INSTALLABLE_EXTRAS="\
lmms \
lmms-vst \
steam \
"

readonly INSTALLABLE_EXTRAS_FLATPAK="\
com.discordapp.Discord \
com.teamspeak.TeamSpeak \
io.github.dummerle.rare \
"

readonly INSTALLABLE_DEV_PKGS="\
scrcpy \
bless \
"

readonly INSTALLABLE_IDE_FLATPAKS="\
ar.xjuan.Cambalache \
cc.arduino.IDE2 \
com.vscodium.codium \
"

readonly INSTALLABLE_NVIDIA_DRIVERS="\
kernel-headers \
kernel-devel \
akmod-nvidia \
xorg-x11-drv-nvidia \
xorg-x11-drv-nvidia-libs \
xorg-x11-drv-nvidia-cuda \
"

#######################################################################################################

dnf copr enable -y nickavem/adw-gtk3
dnf copr remove -y --skip-broken phracek/PyCharm
dnf-install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" # free rpmfusion
dnf-install "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" # nonfree rpmfusion

#######################################################################################################

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
change-ownership "$REAL_USER_HOME"
systemctl enable fstrim.timer

#######################################################################################################

echo "-------------------DNF.CONF----------------"
echo "Setting up dnf.conf..."

command cp -r "$RC_DIR/dnf.conf" "/etc/dnf/dnf.conf"
chown root "/etc/dnf/dnf.conf"
chmod 644 "/etc/dnf/dnf.conf"

echo "Finished copying dnf.conf"

#######################################################################################################
dnf-update-refresh

fwupdmgr refresh --force -y
fwupdmgr get-updates -y
fwupdmgr update -y

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_PACKAGES $INSTALLABLE_CODECS" | tr " " "\n"
dnf-remove "$UNINSTALLABLE_BLOAT"
dnf-install "$INSTALLABLE_PACKAGES"
dnf-install "$INSTALLABLE_CODECS"
dnf-install-group "--with-optional Multimedia"

case "btrfs" in
    "$ROOT_FS" | "$REAL_USER_HOME_FS" |  "$SCRIPT_DIR_FS")
        echo "Found BTRFS, installing tools"
        dnf-install "$INSTALLABLE_BTRFS_TOOLS"
        ;;
    *)
        echo "BTRFS not found; continuing as usual..."
        ;;
esac

readonly GPU=$(lspci | grep -i vga | grep NVIDIA)
if [ ! -z "$GPU" ]; then
    readonly BIOS_MODE=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
    if [[ "$BIOS_MODE" -eq "UEFI" ]]; then
        echo "Signing GPU drivers..."
        # https://blog.monosoul.dev/2022/05/17/automatically-sign-nvidia-kernel-module-in-fedora-36/
        kmodgenca -a
        mokutil --import /etc/pki/akmods/certs/public_key.der
        echo "Finished signing GPU drivers. Make sure you Enroll MOK when you restart."
    else
        echo "UEFI not found; please restart & use UEFI..."
    fi
    echo "Found NVIDIA GPU $GPU, installing drivers..."
    dnf-install "$INSTALLABLE_NVIDIA_DRIVERS"
    
    akmods --force
    dracut --force
fi

#######################################################################################################
# no requirement to add flathub ourselves anymore in f38; it should be enabled by default. however, it may not be, most likely by accident, so this is a failsafe
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS $INSTALLABLE_OBS_STUDIO" | tr " " "\n"
flatpak-install "$INSTALLABLE_FLATPAKS"
flatpak-install "$INSTALLABLE_OBS_STUDIO"

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTRAS $INSTALLABLE_EXTRAS_FLATPAK" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install extras?[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dnf-install "$INSTALLABLE_EXTRAS"
    flatpak-install "$INSTALLABLE_EXTRAS_FLATPAK"
    echo "Finished installing extras."
fi

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS $INSTALLABLE_DEV_PKGS" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install Community IDEs & Jetbrains Toolbox?[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flatpak-install "$INSTALLABLE_IDE_FLATPAKS"
    echo "Finished installing IDEs."
    
    dnf copr enable -y zeno/scrcpy
    dnf-install "$INSTALLABLE_DEV_PKGS"

    echo "-------------------INSTALLING JETBRAINS TOOLBOX----------------" 
    readonly curlsum=$(curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | sha512sum -)
    readonly validsum="9f7b643574de3990ad9afc50d1f82e731c6712c56b7adc91573b639f9322346aa217bdd0005724bc70164274202d617a289f0c7a74be3bd3f5a89d0b2fef3cb7  -"
    if [[ "$validsum" == "$curlsum" ]]; then
        curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
    else
        echo "sha512sum mismatch"        
    fi
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
    dnf-install "$INSTALLABLE_EXTENSIONS"
fi

#######################################################################################################


echo "https://www.suse.com/support/kb/doc/?id=000017060"
while : ; do
    read -p "Please run firefox as a user to create it's configuration directories; let it load fully, then close it.[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

#######################################################################################################

echo "-------------------INSTALLING RC FILES----------------"

cat "$RC_DIR/mimeapps.list" >> "$REAL_USER_HOME/.config/mimeapps.list"
change-ownership "$REAL_USER_HOME/.config/mimeapps.list"

touch "$REAL_USER_HOME/.bashrc_private"
change-ownership "$REAL_USER_HOME/.bashrc_private"

ln -sf "$RC_DIR/.vimrc" "$REAL_USER_HOME/.vimrc"
ln -sf "$RC_DIR/.bashrc" "$REAL_USER_HOME/.bashrc"
ln -sf "$RC_DIR/.nanorc" "$REAL_USER_HOME/.nanorc"
ln -sf "$RC_DIR/.gitconfig" "$REAL_USER_HOME/.gitconfig"
change-ownership "$REAL_USER_HOME/.vimrc" "$REAL_USER_HOME/.bashrc" "$REAL_USER_HOME/.nanorc" "$REAL_USER_HOME/.gitconfig"

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
echo "Finished installing rc files."

#######################################################################################################

ssh-keygen -t rsa -b 4096 -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$SSH_ROOT/id_rsa" -P "" && cat "$SSH_ROOT/id_rsa.pub"

#######################################################################################################

#matching the mkdir
change-ownership-recursive "$CLONED_ROOT" "$MZL_ROOT" "$SSH_ROOT" "$BIN_ROOT" "$WRK_ROOT" "$SMR_ROOT" "$RND_ROOT"

#######################################################################################################

echo 'GRUB_HIDDEN_TIMEOUT=0' >> /etc/default/grub
echo 'GRUB_HIDDEN_TIMEOUT_QUIET=true' >> /etc/default/grub

#######################################################################################################

systemctl restart NetworkManager
hostnamectl hostname "$DISTRIBUTION_NAME"

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "Couldn't updatedb, retrying with absolute path"
    /usr/sbin/updatedb
fi

#######################################################################################################
echo "--------------------------- GNOME ---------------------------"
echo "Make sure to get the legacy (GTK3) Theme Auto Switcher"
echo "  https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/"
echo "Make sure to get Dash to Panel"
echo "  https://extensions.gnome.org/extension/1160/dash-to-panel/"
echo "--------------------------- FSTAB ---------------------------"
echo "Remember to add a permanent mount point for permanently mounted partitions."
echo "Standard fstab USER mount arguments:"
echo "  rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "Standard fstab ROOT mount arguments:"
echo "  nouser,nosuid,nodev,nofail,x-gvfs-show,x-udisks-auth"
echo "--------------------------- VISUDO ---------------------------"
echo "Please sudo visudo and add:"
echo "  Defaults env_reset, timestamp_timeout=120, pwfeedback"
echo "--------------------------- LIMITS ---------------------------"
echo "sudo nano /etc/security/limits.conf"
echo "$REAL_USER hard nproc 10000"
echo "$REAL_USER hard maxlogins 2"
echo "* - maxsyslogins 4"
echo "--------------------------- SWAP ---------------------------"
echo "If using ext4 in /, create a swapfile with these commands:"
echo "16GB:"
echo "  sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo "32GB:"
echo "  sudo fallocate -l 32G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo "64GB:"
echo "  sudo fallocate -l 64G /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
echo ""
echo "It's possible this swapfile won't persist after reboots; confirm with:"
echo "  sudo swapon --show"
echo "If this is the case, make permanent by appending this line in /etc/fstab:"
echo "  /swapfile swap swap defaults 0 0"
echo "------------------------------------------------------"
echo "Increase the number of memory map areas a process may have. No need for it in fedora 39 or higher. Relevant links:"
echo "  https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount"
echo "  https://kernel.org/doc/Documentation/sysctl/vm.txt"
echo "To modify, sudo nano /etc/sysctl.conf and append this line: "
echo "  vm.max_map_count=2147483642"
echo "Verify with sysctl vm.max_map_count"
echo "------------------------------------------------------"
echo "Make sure to restart your PC after making all the necessary adjustments."
echo "------------------------------------------------------"
