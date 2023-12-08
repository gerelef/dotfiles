#!/usr/bin/env -S sudo --preserve-env="XDG_RUNTIME_DIR" --preserve-env="XDG_DATA_DIRS" --preserve-env="DBUS_SESSION_BUS_ADDRESS" bash

# ref: https://askubuntu.com/a/30157/8698
if ! [ $(id -u) = 0 ]; then
    echo "The script needs to be run as root." >&2
    exit 2
fi

if [[ -z $XDG_RUNTIME_DIR || -z $XDG_DATA_DIRS || -z $DBUS_SESSION_BUS_ADDRESS ]]; then
    echo "XDG_RUNTIME_DIR, XDG_DATA_DIRS, DBUS_SESSION_BUS_ADDRESS must be set for this script to work."
    echo "Check the script's shebang for more information on how to correctly run this script."
    exit 2
fi

readonly DIR=$(dirname -- "$BASH_SOURCE")
source "$DIR/common-utils.sh"

# create default directories that should exist on all my systems
create-default-locations 

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
flameshot \
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
rhythmbox \
totem \
cheese \
gnome-tour \
gnome-weather \
gnome-remote-desktop \
gnome-font-viewer \
gnome-characters \
gnome-classic-session \
gnome-initial-setup \
gnome-terminal \
gnome-boxes \
gnome-calculator \
gnome-calendar \
gnome-color-manager \
gnome-contacts \
gnome-maps \
"

readonly INSTALLABLE_FLATPAKS="\
com.spotify.Client \
com.raggesilver.BlackBox \
com.github.rafostar.Clapper \
net.cozic.joplin_desktop \
de.haeckerfelix.Fragments \
com.skype.Client \
us.zoom.Zoom \
io.gitlab.theevilskeleton.Upscaler \
org.gtk.Gtk3theme.adw-gtk3 \
org.gtk.Gtk3theme.adw-gtk3-dark \
com.github.tchx84.Flatseal \
org.gnome.Snapshot \
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
dnf install -y --best --allowerasing "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" # free rpmfusion
dnf install -y --best --allowerasing "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" # nonfree rpmfusion

#######################################################################################################

# https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
# Make home directory private
change-ownership "$REAL_USER_HOME"
systemctl enable fstrim.timer
# make sure we're booting into a DE next time we reboot
systemctl set-default graphical.target

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
        if ask-user 'Do you want to enroll MOK and restart?'; then
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

# https://forums.developer.nvidia.com/t/no-matching-gpu-found-with-510-47-03/202315/5
[[ $CHASSIS_TYPE == "Desktop" ]] && systemctl disable nvidia-powerd.service

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

if ask-user 'Are you sure you want to install extras?'; then    
    echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTRAS $INSTALLABLE_EXTRAS_FLATPAK" | tr " " "\n"
    dnf-install "$INSTALLABLE_EXTRAS"
    dnf-install "$INSTALLABLE_OBS_STUDIO"
    flatpak-install "$INSTALLABLE_EXTRAS_FLATPAK"
    echo "Done."
fi

if ask-user "Are you sure you want to install the Wine Compatibility layer?"; then
    echo "-------------------INSTALLING---------------- $INSTALLABLE_WINE_GE_CUSTOM_PKGS" | tr " " "\n"
    dnf-install "$INSTALLABLE_WINE_GE_CUSTOM_PKGS"
    echo "Done."
fi

if ask-user "Are you sure you want to install Community IDEs & Jetbrains Toolbox?"; then
    echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS $INSTALLABLE_DEV_PKGS" | tr " " "\n"
    dnf groupinstall -y --best --allowerasing "C Development Tools and Libraries"
    dnf groupinstall -y --best --allowerasing "Development Tools"

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

if ask-user "Are you sure you want to install zeno/scrcpy?"; then
    echo "Installing zeno/scrcpy ..."
    dnf copr enable -y zeno/scrcpy
    dnf-install scrcpy
fi

#######################################################################################################

if ask-user "Do you want to install extensions?"; then
    echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTENSIONS" | tr " " "\n"
    dnf-install "$INSTALLABLE_EXTENSIONS"
    echo "Done."
fi

if ask-user "Do you want to install gnome backgrounds?"; then
    echo "-------------------INSTALLING----------------" | tr " " "\n"
    dnf install -y --best --allowerasing f*-backgrounds-gnome*
    echo "Done."
fi

#######################################################################################################


echo "https://www.suse.com/support/kb/doc/?id=000017060"
while : ; do
    change-ownership-recursive "$MZL_ROOT"
    if ask-user "Please run firefox as a user to create it's configuration directories; let it load fully, then close it."; then
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
ssh-keygen -q -t ed25519 -N '' -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$SSH_ROOT/id_ed25519" -P "" <<< $'\ny' >/dev/null 2>&1
cat "$SSH_ROOT/id_ed25519.pub"

#######################################################################################################

# if we haven't modified GRUB already, go ahead...
readonly DEFAULT_GRUB_CFG="/etc/default/grub"
if [[ -z $(cat $DEFAULT_GRUB_CFG | grep "GRUB_HIDDEN_TIMEOUT") ]]; then
    dnf-install "hwinfo"
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
    fallocate -l "$kbs"KB /swapfile 
    chmod 600 /swapfile 
    chown root /swapfile 
    mkswap /swapfile 
    swapon /swapfile
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

#######################################################################################################

# heredocs
# https://tldp.org/LDP/abs/html/here-docs.html
sudo --preserve-env="XDG_RUNTIME_DIR" --preserve-env="XDG_DATA_DIRS" --preserve-env="DBUS_SESSION_BUS_ADDRESS" -u "$REAL_USER" bash <<-GSETTINGS_DELIMITER
    source "$(dirname -- "$BASH_SOURCE")/common-utils.sh"
    
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    add-gsettings-shortcut "blackbox" "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=blackbox com.raggesilver.BlackBox" "<Shift><Control>KP_Add"
    add-gsettings-shortcut "gnome-system-monitor" "gnome-system-monitor" "<Shift><Control>Escape"
    
    # reference to fix https://github.com/flameshot-org/flameshot/issues/3326#issuecomment-1838662244
    dbus-send --session --print-reply=literal --dest=org.freedesktop.impl.portal.PermissionStore /org/freedesktop/impl/portal/PermissionStore org.freedesktop.impl.portal.PermissionStore.SetPermission string:'screenshot' boolean:true string:'screenshot' string:'flameshot' array:string:'yes'
    dbus-send --session --print-reply=literal --dest=org.freedesktop.impl.portal.PermissionStore /org/freedesktop/impl/portal/PermissionStore org.freedesktop.impl.portal.PermissionStore.Lookup string:'screenshot' string:'screenshot'
    add-gsettings-shortcut "flameshot" "flameshot gui" "Print"
    
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox command-as-login-shell true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox cursor-shape 1
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox custom-shell-command ''
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox delay-before-showing-floating-controls 400
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox easy-copy-paste true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox fill-tabs true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox floating-controls false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox floating-controls-hover-area 10
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox font 'Monospace 12'
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox headerbar-drag-area false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox pixel-scrolling false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox pretty true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox remember-window-size false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox scrollback-mode 1
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox show-headerbar true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox show-menu-button true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox show-scrollbars true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox style-preference 0
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox terminal-cell-height 1.0
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox terminal-cell-width 1.0
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox theme-dark 'One Dark'
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox theme-light 'Tomorrow'
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox use-custom-command false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox use-overlay-scrolling true
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox window-width 1280
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox.terminal.search match-case-sensitive false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox.terminal.search match-regex false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox.terminal.search match-whole-words false
    flatpak run --branch=stable --arch=x86_64 --command=gsettings com.raggesilver.BlackBox set com.raggesilver.BlackBox.terminal.search wrap-around true
    gsettings set org.gnome.nautilus.preferences show-create-link true
    gsettings set org.gnome.nautilus.preferences show-delete-permanently false
    gsettings set org.gnome.nautilus.preferences show-hidden-files true
    gsettings set org.gnome.nautilus.preferences recursive-search 'local-only'
    gsettings set org.gnome.nautilus.preferences mouse-use-extra-buttons false
    gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
    gsettings set org.gtk.Settings.FileChooser clock-format '24h'
    gsettings set org.gtk.Settings.FileChooser date-format 'regular'
    gsettings set org.gtk.Settings.FileChooser show-hidden true
    gsettings set org.gtk.Settings.FileChooser show-size-column true
    gsettings set org.gtk.Settings.FileChooser show-type-column true
    gsettings set org.gtk.Settings.FileChooser sort-directories-first true
    gsettings set org.gtk.Settings.FileChooser type-format 'category'
    gsettings set org.gtk.Settings.FileChooser sidebar-width 140
    gsettings set org.gtk.gtk4.Settings.FileChooser clock-format '24h'
    gsettings set org.gtk.gtk4.Settings.FileChooser date-format 'regular'
    gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true
    gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
    gsettings set org.gtk.gtk4.Settings.FileChooser type-format 'category'
    gsettings set org.gtk.gtk4.Settings.FileChooser view-type 'list'
    gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
    gsettings set org.gnome.shell.keybindings screenshot "[]"
    gsettings set org.gnome.shell.keybindings screenshot-window "[]"
    gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"
    gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['Menu']"
    gsettings set org.gnome.desktop.wm.keybindings always-on-top  "[]"
    gsettings set org.gnome.desktop.wm.keybindings begin-move  "[]"
    gsettings set org.gnome.desktop.wm.keybindings begin-resize  "[]"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>d']"
    gsettings set org.gnome.desktop.wm.keybindings cycle-group "['<Alt>grave']"
    gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "['<Shift><Alt>grave']"
    gsettings set org.gnome.desktop.wm.keybindings cycle-panels  "[]"
    gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward  "[]"
    gsettings set org.gnome.desktop.wm.keybindings cycle-windows  "[]"
    gsettings set org.gnome.desktop.wm.keybindings cycle-windows-backward  "[]"
    gsettings set org.gnome.desktop.wm.keybindings lower  "[]"
    gsettings set org.gnome.desktop.wm.keybindings maximize  "[]"
    gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally  "[]"
    gsettings set org.gnome.desktop.wm.keybindings maximize-vertically  "[]"
    gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>z']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-center  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-e  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-n  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-s  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-w  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>Home']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-11  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-12  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last  "[]"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Control>Home']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Control>End']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up  "[]"
    gsettings set org.gnome.desktop.wm.keybindings panel-main-menu  "[]"
    gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Alt>F2']"
    gsettings set org.gnome.desktop.wm.keybindings raise  "[]"
    gsettings set org.gnome.desktop.wm.keybindings raise-or-lower  "[]"
    gsettings set org.gnome.desktop.wm.keybindings set-spew-mark  "[]"
    gsettings set org.gnome.desktop.wm.keybindings show-desktop  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-group  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-group-backward  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space']"
    gsettings set org.gnome.desktop.wm.keybindings switch-panels  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Primary><Super>Down', '<Primary><Super>j']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Control>Home']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control>End']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Primary><Super>Up', '<Primary><Super>k']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows  "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward  "[]"
    gsettings set org.gnome.desktop.wm.keybindings toggle-above  "[]"
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen  "[]"
    gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>x']"
    gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces  "[]"
    gsettings set org.gnome.desktop.wm.keybindings unmaximize  "[]"
    gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
    gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'none'
    gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'menu'
    gsettings set org.gnome.desktop.wm.preferences audible-bell true
    gsettings set org.gnome.desktop.wm.preferences auto-raise false
    gsettings set org.gnome.desktop.wm.preferences auto-raise-delay 500
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'
    gsettings set org.gnome.desktop.wm.preferences disable-workarounds false
    gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
    gsettings set org.gnome.desktop.wm.preferences focus-new-windows 'smart'
    gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
    gsettings set org.gnome.desktop.wm.preferences raise-on-click true
    gsettings set org.gnome.desktop.wm.preferences resize-with-right-button false
    gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita'
    gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font true
    gsettings set org.gnome.desktop.wm.preferences visual-bell false
    gsettings set org.gnome.desktop.wm.preferences visual-bell-type 'fullscreen-flash'
    gsettings set org.gnome.desktop.wm.preferences workspace-names  "[]"
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
    gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
    gsettings set org.gnome.desktop.peripherals.touchpad click-method 'none'
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
    gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
    gsettings set org.gnome.desktop.peripherals.touchpad left-handed 'mouse'
    gsettings set org.gnome.desktop.peripherals.touchpad middle-click-emulation false
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
    gsettings set org.gnome.desktop.peripherals.touchpad speed 0.10000000000000001
    gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
    gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag-lock false
    gsettings set org.gnome.desktop.peripherals.touchpad tap-button-map 'default'
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
    gsettings set org.gnome.TextEditor auto-indent true
    gsettings set org.gnome.TextEditor highlight-current-line true
    gsettings set org.gnome.TextEditor indent-style 'space'
    gsettings set org.gnome.TextEditor restore-session true
    gsettings set org.gnome.TextEditor right-margin-position 80
    gsettings set org.gnome.TextEditor show-line-numbers true
    gsettings set org.gnome.TextEditor show-map true
    gsettings set org.gnome.TextEditor spellcheck false
    gsettings set org.gnome.TextEditor tab-width 4
    gsettings set org.gnome.TextEditor use-system-font true
    gsettings set org.gnome.TextEditor wrap-text false
    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface clock-show-date false
    gsettings set org.gnome.desktop.interface clock-show-seconds true
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    gsettings set org.gnome.desktop.interface cursor-blink true
    gsettings set org.gnome.desktop.interface enable-hot-corners false
    gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
    gsettings set org.gnome.desktop.interface font-hinting 'full'
    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false
    gsettings set org.gnome.desktop.interface menubar-detachable false
    gsettings set org.gnome.desktop.interface overlay-scrolling true
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.media-handling automount true
    gsettings set org.gnome.desktop.media-handling automount-open true
    gsettings set org.gnome.desktop.media-handling autorun-never true
    gsettings set org.gnome.desktop.notifications show-banners false
    gsettings set org.gnome.desktop.notifications show-in-lock-screen true
    gsettings set org.gnome.desktop.peripherals.keyboard numlock-state false
    gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state false
    gsettings set org.gnome.desktop.peripherals.keyboard repeat true
    gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
    gsettings set org.gnome.desktop.peripherals.mouse double-click 250
    gsettings set org.gnome.desktop.peripherals.mouse middle-click-emulation false
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
    gsettings set org.gnome.desktop.peripherals.mouse speed -0.2
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
    gsettings set org.gnome.desktop.privacy disable-camera true
    gsettings set org.gnome.desktop.privacy disable-microphone false
    gsettings set org.gnome.desktop.privacy disable-sound-output false
    gsettings set org.gnome.desktop.privacy hide-identity false
    gsettings set org.gnome.desktop.privacy old-files-age 7
    gsettings set org.gnome.desktop.privacy recent-files-max-age -1
    gsettings set org.gnome.desktop.privacy remember-app-usage true
    gsettings set org.gnome.desktop.privacy remember-recent-files false
    gsettings set org.gnome.desktop.privacy remove-old-temp-files true
    gsettings set org.gnome.desktop.privacy remove-old-trash-files false
    gsettings set org.gnome.desktop.privacy show-full-name-in-top-bar false
    gsettings set org.gnome.desktop.privacy usb-protection true
    gsettings set org.gnome.desktop.privacy usb-protection-level 'lockscreen'
    gsettings set org.gnome.system.location enabled true
    gsettings set org.gnome.system.location max-accuracy-level 'city'
    gsettings set org.gnome.desktop.remote-desktop.rdp enable false
    gsettings set org.gnome.desktop.screensaver color-shading-type 'solid'
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent false
    gsettings set org.gnome.desktop.sound event-sounds true
    gsettings set org.gnome.mutter attach-modal-dialogs true
    gsettings set org.gnome.mutter auto-maximize true
    gsettings set org.gnome.mutter center-new-windows true
    gsettings set org.gnome.mutter check-alive-timeout 15000
    gsettings set org.gnome.shell.weather automatic-location true
    gsettings set org.gnome.software allow-updates false
    gsettings set org.gnome.software download-updates false
    gsettings set org.gnome.software download-updates-notify true
    gsettings set org.gnome.software enable-repos-dialog true
    gsettings set org.gnome.software show-nonfree-ui true
    gsettings set org.gnome.software show-ratings true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0.0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 6.0
    exit
GSETTINGS_DELIMITER
