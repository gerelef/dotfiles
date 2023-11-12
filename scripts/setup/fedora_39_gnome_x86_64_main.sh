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

# fs thingies
readonly ROOT_FS=$(stat -f --format=%T /)
readonly REAL_USER_HOME_FS=$(stat -f --format=%T "$REAL_USER_HOME")
readonly DISTRIBUTION_NAME="fedora$(rpm -E %fedora)"

readonly INSTALLABLE_PACKAGES="\
flatpak \
adw-gtk3-theme \
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

readonly INSTALLABLE_OBS_STUDIO="\
obs-studio \
obs-studio-plugin-vkcapture \
obs-studio-plugin-vlc-video \
obs-studio-plugin-webkitgtk \
obs-studio-plugin-x264 \
"

readonly INSTALLABLE_PWR_MGMNT="\
tlp \
tlp-rdw \
powertop \
"

readonly UNINSTALLABLE_BLOAT="\
rhythmbox* \
totem \
cheese \
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
org.gnome.Snapshot \
com.spotify.Client \
com.raggesilver.BlackBox \
de.haeckerfelix.Fragments \
org.gtk.Gtk3theme.adw-gtk3 \
org.gtk.Gtk3theme.adw-gtk3-dark \
io.gitlab.daikhan.stable \
io.gitlab.theevilskeleton.Upscaler \
page.codeberg.Imaginer.Imaginer \
net.cozic.joplin_desktop \
com.skype.Client \
us.zoom.Zoom \
com.github.tchx84.Flatseal \
"

readonly INSTALLABLE_EXTENSIONS="\
gnome-shell-extension-places-menu \
gnome-shell-extension-forge \
gnome-shell-extension-dash-to-panel \
gnome-extensions-app \
f$(rpm -E %fedora)-backgrounds-extras-gnome \
"

readonly INSTALLABLE_BTRFS_TOOLS="\
btrfs-assistant \
timeshift \
"

readonly INSTALLABLE_EXTRAS="\
mixxx \
steam \
gamescope \
"

readonly INSTALLABLE_EXTRAS_FLATPAK="\
com.discordapp.Discord \
com.teamspeak.TeamSpeak \
"

readonly INSTALLABLE_DEV_PKGS="\
cmake \
ninja-build \
clang \
scrcpy \
bless \
"

readonly INSTALLABLE_IDE_FLATPAKS="\
ar.xjuan.Cambalache \
com.visualstudio.code \
"

readonly INSTALLABLE_NVIDIA_DRIVERS="\
gcc \
kernel-headers \
kernel-devel \
akmod-nvidia \
xorg-x11-drv-nvidia \
xorg-x11-drv-nvidia-libs \ 
xorg-x11-drv-nvidia-libs.i686 \
xorg-x11-drv-nvidia-cuda \
xorg-x11-drv-nvidia-power \
"

readonly INSTALLABLE_WINE_GE_CUSTOM_PKGS="\
wine \
winetricks \
protontricks \
vulkan-loader \
vulkan-loader.i686 \
"

#######################################################################################################

echo "-------------------DNF.CONF----------------"
echo "Setting up dnf.conf..."

copy-dnf

echo "Done."

#######################################################################################################

# for some reason this repository is added on every new install, i dont' care i have toolbox wtf
dnf copr remove -y --skip-broken phracek/PyCharm
# i don't want google chrome ma boi please stahp
dnf config-manager --set-disabled google-chrome 
dnf-install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" # free rpmfusion
dnf-install "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" # nonfree rpmfusion

#######################################################################################################

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
change-ownership "$REAL_USER_HOME"
systemctl enable fstrim.timer

#######################################################################################################
dnf-update-refresh

readonly BIOS_MODE=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
if [[ "$BIOS_MODE" == "UEFI" ]]; then
    echo "Updating UEFI with fwupdmgr..."
    fwupdmgr refresh --force -y
    fwupdmgr get-updates -y
    fwupdmgr update -y
else
    echo 'UEFI not found!'
fi

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_PACKAGES" | tr " " "\n"
dnf-remove "$UNINSTALLABLE_BLOAT"
dnf-install "$INSTALLABLE_PACKAGES"

if [[ "btrfs" == $ROOT_FS || "btrfs" == $REAL_USER_HOME_FS ]]; then
    echo "Found BTRFS, installing tools..."
    dnf-install "$INSTALLABLE_BTRFS_TOOLS"
fi

readonly NVIDIA_GPU=$(lspci | grep -i vga | grep NVIDIA)
if [[ -n "$NVIDIA_GPU" && $(lsmod | grep nouveau) ]]; then
    echo "-------------------INSTALLING NVIDIA DRIVERS----------------"
    echo "Found $NVIDIA_GPU running with nouveau drivers!"
    if [[ "$BIOS_MODE" == "UEFI" && $(mokutil --sb-state 2> /dev/null) ]]; then
        # https://blog.monosoul.dev/2022/05/17/automatically-sign-nvidia-kernel-module-in-fedora-36/
        while : ; do
            read -p "Do you want to enroll MOK and restart?[Y/n] " -n 1 -r
            [[ ! $REPLY =~ ^[YyNn]$ ]] || break
        done
        
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Signing GPU drivers..."
            kmodgenca -a
            mokutil --import /etc/pki/akmods/certs/public_key.der
            echo "Finished signing GPU drivers. Make sure you Enroll MOK when you restart."
            echo "OK."
            exit 0
        fi
    else
        echo "UEFI not found; please restart & use UEFI..."
    fi
    dnf-install "$INSTALLABLE_NVIDIA_DRIVERS"
    
    akmods --force && dracut --force
    
    # check arch wiki, these enable DRM
    grubby --update-kernel=ALL --args="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
fi

readonly CHASSIS_TYPE="$(dmidecode --string chassis-type)"
if [[ $CHASSIS_TYPE == "Sub Notebook" || $CHASSIS_TYPE == "Laptop" || $CHASSIS_TYPE == "Notebook" || 
      $CHASSIS_TYPE == "Hand Held" || $CHASSIS_TYPE == "Portable" ]]; then
    # s3 sleep
    grubby --update-kernel=ALL --args="mem_sleep_default=s2idle" # modern standby
    echo "-------------------OPTIMIZING BATTERY USAGE----------------"
    echo "Found laptop $CHASSIS_TYPE"
    dnf-install "$INSTALLABLE_PWR_MGMNT"
    systemctl mask power-profiles-daemon
    powertop --auto-tune
fi

echo "Done."

echo "-------------------INSTALLING CODECS / H/W VIDEO ACCELERATION----------------"

# based on https://github.com/devangshekhawat/Fedora-39-Post-Install-Guide
dnf-groupupdate 'core' 'multimedia' 'sound-and-video' --setop='install_weak_deps=False' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
dnf install -y --best --allowerasing gstreamer1-plugins-{bad-\*,good-\*,base}
dnf install -y --best --allowerasing lame\* --exclude=lame-devel
dnf-install "gstreamer1-plugin-openh264" "gstreamer1-libav" "--exclude=gstreamer1-plugins-bad-free-devel" "ffmpeg" "gstreamer-ffmpeg"
dnf groupinstall -y --best --allowerasing --with-optional "Multimedia"

dnf-install "ffmpeg" "ffmpeg-libs" "libva" "libva-utils"
dnf config-manager --set-enabled fedora-cisco-openh264
dnf-install "openh264" "gstreamer1-plugin-openh264" "mozilla-openh264"

#######################################################################################################
# no requirement to add flathub ourselves anymore in f38; it should be enabled by default. however, it may not be, most likely by accident, so this is a failsafe
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-delete fedora

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS" | tr " " "\n"
flatpak-install "$INSTALLABLE_FLATPAKS"

echo "Done."

#######################################################################################################

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTRAS $INSTALLABLE_EXTRAS_FLATPAK" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install extras?[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dnf-install "$INSTALLABLE_EXTRAS"
    dnf-install "$INSTALLABLE_OBS_STUDIO"
    flatpak-install "$INSTALLABLE_EXTRAS_FLATPAK"
    echo "Done."
fi

echo "-------------------INSTALLING---------------- $INSTALLABLE_WINE_GE_CUSTOM_PKGS" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install the Wine Compatibility layer?[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing tools for Wine..."
    dnf-install "$INSTALLABLE_WINE_GE_CUSTOM_PKGS"
    echo "Done."
fi

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS $INSTALLABLE_DEV_PKGS" | tr " " "\n"
while : ; do
    read -p "Are you sure you want to install Community IDEs & Jetbrains Toolbox?[Y/n] " -n 1 -r
    [[ ! $REPLY =~ ^[YyNn]$ ]] || break
done

echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dnf groupinstall -y --best --allowerasing "C Development Tools and Libraries"
    dnf groupinstall -y --best --allowerasing "Development Tools"

    dnf copr enable -y zeno/scrcpy
    dnf-install "$INSTALLABLE_DEV_PKGS"
    
    flatpak-install "$INSTALLABLE_IDE_FLATPAKS"
    echo "Finished installing IDEs."
    echo "-------------------INSTALLING JETBRAINS TOOLBOX----------------"
    readonly curlsum=$(curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | sha512sum -)
    readonly validsum="7eb50db1e6255eed35b27c119463513c44aee8e06f3014609a410033f397d2fd81d2605e4e5c243b1087a6c23651f6b549a7c4ee386d50a22cc9eab9e33c612e  -"
    if [[ "$validsum" == "$curlsum" ]]; then
        # we're overriding $HOME for this script since it doesn't know we're running as root
        #  and looks for $HOME, ruining everything in whatever "$HOME/.local/share/JetBrains/Toolbox/bin" and "$HOME/.local/bin" resolve into
        (HOME="$REAL_USER_HOME" && curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash)
    else
        echo "sha512sum mismatch"
    fi
    echo "Done."
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
    echo "Done."
fi

#######################################################################################################


echo "https://www.suse.com/support/kb/doc/?id=000017060"
while : ; do
    change-ownership-recursive "$MZL_ROOT"
    read -p "Please run firefox as a user to create it's configuration directories; let it load fully, then close it.[Y/n] " -n 1 -r
    
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        copy-ff-rc-files
        echo "Done."
        break
    fi
done

#######################################################################################################

echo "-------------------INSTALLING RC FILES----------------"

copy-pipewire
create-private-bashrc
create-private-gitconfig
copy-rc-files

echo "Done."

echo "-------------------SETTING UP SYSTEM DEFAULTS----------------"

lower-swappiness
echo "Lowered swappiness."
raise-user-watches
echo "Raised user watches."
cap-nproc-count
echo "Capped maximum number of processes."
cap-max-logins-system
echo "Capped max system logins."
create-convenience-sudoers
echo "Created sudoers.d convenience defaults."

echo "Done."

#######################################################################################################
ssh-keygen -q -t rsa -b 4096 -N '' -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$SSH_ROOT/id_rsa" -P "" <<< $'\ny' >/dev/null 2>&1
cat "$SSH_ROOT/id_rsa.pub"

#######################################################################################################

# if we haven't modified GRUB already, go ahead...
readonly DEFAULT_GRUB_CFG="/etc/default/grub"
if [[ -z $(cat $DEFAULT_GRUB_CFG | grep "GRUB_HIDDEN_TIMEOUT") ]]; then
    out="$(sed -r 's/GRUB_TERMINAL_OUTPUT=.+/GRUB_TERMINAL_OUTPUT="gfxterm"/' < $DEFAULT_GRUB_CFG)" 
    echo "$out" | dd of="$DEFAULT_GRUB_CFG"
    
    echo 'GRUB_HIDDEN_TIMEOUT=0' >> /etc/default/grub
    echo 'GRUB_HIDDEN_TIMEOUT_QUIET=true' >> /etc/default/grub
    echo 'GRUB_GFXPAYLOAD_LINUX=keep' >> /etc/default/grub
    top_res="$(hwinfo --framebuffer | tail -n 2 | grep -E -o '[0-9]{3,4}x[0-9]{3,4}')"
    top_dep="$(hwinfo --framebuffer | tail -n 2 | grep Mode | grep -E -o ', [0-9]{2} bits' | grep -E -o '[0-9]{2}')"
    echo "GRUB_GFXMODE=$top_res x $top_dep" | tr -d ' ' >> /etc/default/grub
    
    readonly GRUB_OUT_LOCATION="$(locate grub.cfg | grep /boot | head -n 1)"
    [[ -n $GRUB_OUT_LOCATION ]] && grub2-mkconfig --output="$GRUB_OUT_LOCATION"
fi

#######################################################################################################

systemctl restart NetworkManager
timedatectl set-local-rtc '0' # for fixing dual boot time inconsistencies
hostnamectl hostname "$DISTRIBUTION_NAME"
# if the statement below doesnt work, check this out
#  https://old.reddit.com/r/linuxhardware/comments/ng166t/s3_deep_sleep_not_working/
systemctl disable NetworkManager-wait-online.service # stop network manager from waiting until online, improves boot times
rm /etc/xdg/autostart/org.gnome.Software.desktop # stop this from updating in the background and eating ram, no reason

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "updatedb errored, retrying with absolute path"
    /usr/sbin/updatedb
fi

#######################################################################################################
# if we haven't created /swapfile, go ahead...
if [[ -z $(cat /etc/fstab | grep "/swapfile swap swap defaults 0 0") ]]; then
    kbs=$(cat /proc/meminfo | grep MemTotal | grep -E -o "[0-9]+")
    fallocate -l "$kbs"KB /swapfile && sudo chmod 600 /swapfile && sudo chown root /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

echo "--------------------------- GNOME ---------------------------"
echo "Make sure to get the legacy GTK3 Theme Auto Switcher"
echo "  https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/"
echo "--------------------------- FSTAB ---------------------------"
echo "User fstab mount arguments: rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "------------------------------------------------------"
echo "Remember to add a permanent mount point for internal storage partitions."
echo "Make sure to restart your PC after making all the necessary adjustments."

#######################################################################################################

# everything in home should be owned by the user and in the user's group
change-ownership-recursive "$REAL_USER_HOME" 2> /dev/null
change-group-recursive "$REAL_USER_HOME" 2> /dev/null
