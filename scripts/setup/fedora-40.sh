#!/usr/bin/env -S sudo --preserve-env="XDG_CURRENT_DESKTOP" --preserve-env="XDG_RUNTIME_DIR" --preserve-env="XDG_DATA_DIRS" --preserve-env="DBUS_SESSION_BUS_ADDRESS" bash

readonly DIR=$(dirname -- "$BASH_SOURCE")

[[ -f "$DIR/common-utils.sh" ]] || ( echo "$DIR/common-utils.sh doesn't exist! exiting..." && exit 2 )
source "$DIR/common-utils.sh"

# DEPENDENCIES FOR THE CURRENT SCRIPT
dnf-install flatpak curl plocate pciutils udisks2 dnf5

# change dnf4 to dnf5 (preview/unstable: is supposed to be shipped with fedora-41)
update-alternatives --install /usr/bin/dnf dnf /usr/bin/dnf5 1
dnf-install "dnf5-command(config-manager)"

install-gnome-essentials () (
    echo-status "-------------------INSTALLING GNOME----------------"
    dnf-install "$INSTALLABLE_ESSENTIAL_DESKTOP_PACKAGES"
    dnf-install "f$(rpm -E %fedora)-backgrounds-gnome"
    # gnome currently supports X11; when xorg is dropped by GNOME, this will need to be removed
    dnf-group-install base-x
    
    dnf-install "$INSTALLABLE_GNOME_ESSENTIAL_PACKAGES"
    dnf-install "$INSTALLABLE_GNOME_APPLICATION_PACKAGES"
    dnf-install "$INSTALLABLE_ADWAITA_PACKAGES" "$INSTALLABLE_GNOME_EXTENSIONS"
    flatpak-install "$INSTALLABLE_GNOME_FLATPAKS"
    
    try-enabling-power-profiles-daemon
    
    systemctl enable gdm
    configure-gdm-dconf
    
    echo-success "Done."
)

install-cinnamon-essentials () (
    echo-status "-------------------INSTALLING CINNAMON----------------"
    dnf-install "$INSTALLABLE_ESSENTIAL_DESKTOP_PACKAGES"
    dnf-install "f$(rpm -E %fedora)-backgrounds-gnome"
    # cinnamon is currently X11 only; when xorg is dropped by Cinnamon, this will need to be removed
    dnf-group-install base-x
    
    dnf-install "$INSTALLABLE_CINNAMON_ESSENTIAL_PACKAGES"
    dnf-install "$INSTALLABLE_CINNAMON_APPLICATION_PACKAGES"
    dnf-install "$INSTALLABLE_CINNAMON_EXTENSIONS"
    flatpak-install "$INSTALLABLE_CINNAMON_FLATPAKS"

    try-enabling-power-profiles-daemon
    
    systemctl enable lightdm

    echo-success "Done."
)

configure-gdm-dconf () (
    echo-status "-------------------CONFIGURING GDM DCONF DB & USER GSETTINGS----------------"
    create-gdm-dconf-profile
    create-gdm-dconf-db

    dconf update
    echo-debug "Updated dconf db."
)

install-universal-necessities () (
    echo-status "-------------------INSTALLING ESSENTIAL PACKAGES----------------"
    dnf-install "$INSTALLABLE_ESSENTIAL_PACKAGES"
    dnf-install "$INSTALLABLE_PIPEWIRE_PACKAGES"
    
    dnf-group-install-with-optional "hardware-support" "networkmanager-submodules" "printing"
    
    dnf-install "$INSTALLABLE_APPLICATION_PACKAGES"
    flatpak-install "$INSTALLABLE_FLATPAKS"

    if is-btrfs-rootfs || is-btrfs-homefs; then
        echo-status "Found BTRFS, installing tools..."
        dnf-install "$INSTALLABLE_BTRFS_TOOLS"
    fi
    
    # https://github.com/flameshot-org/flameshot/issues/3326#issuecomment-1855332738
    (cat <<GDM_END
#!/bin/bash
flameshot gui
GDM_END
    ) > "/usr/local/bin/flameshot-gui-workaround"
    chmod a+x "/usr/local/bin/flameshot-gui-workaround"
    flameshot config -m white
    echo-debug "Configured flameshot."
    
    (cat <<GR_END
#!/bin/sh
set -e
exec grub2-mkconfig -o /boot/grub2/grub.cfg "$@"
GR_END
    ) > "/usr/sbin/update-grub"
    chown root:root "/usr/sbin/update-grub"
    chmod 755 "/usr/sbin/update-grub"
    echo-debug "Configured update-grub."

    echo-success "Done."
)

optimize-hardware () (
    echo-status "-------------------OPTIMIZING HARDWARE----------------"
    
    if is-uefi; then
        echo-status "Updating UEFI with fwupdmgr..."
        fwupdmgr refresh --force -y
        fwupdmgr get-updates -y
        fwupdmgr update -y
    fi
    
    if is-desktop-type; then
        echo-status "Disabling mobile-gpu specific service (https://forums.developer.nvidia.com/t/no-matching-gpu-found-with-510-47-03/202315/5)"
        systemctl disable nvidia-powerd.service
        return
    fi
    
    echo-success "Done."
)

optimize-laptop-battery () (
    # if we're on anything but a mobile device, gtfo
    ! is-mobile-type && return 0
    
    echo-status "-------------------OPTIMIZING LAPTOP BATTERY----------------"
    echo-status "Found mobile device type"
    # s3 sleep
    grubby --update-kernel=ALL --args="mem_sleep_default=s2idle"
    dnf-install "$INSTALLABLE_PWR_MGMNT"
    powertop --auto-tune

    echo-success "Done."
)

install-proprietary-nvidia-drivers () (
    # install nvidia drivers if we have an NVIDIA card
    if ! is-nvidia-gpu; then return; fi 
    
    readonly NVIDIA_GPU="$(get-nvidia-gpu-model)"
    
    echo-status "-------------------INSTALLING NVIDIA DRIVERS----------------"
    echo-status "Found $NVIDIA_GPU running with nouveau drivers!"
    
    if is-uefi && [[ $(mokutil --sb-state 2> /dev/null) ]]; then
        # https://blog.monosoul.dev/2022/05/17/automatically-sign-nvidia-kernel-module-in-fedora-36/
        # https://github.com/NVIDIA/yum-packaging-precompiled-kmod/blob/main/UEFI.md
        # the official NVIDIA instructions recommend installing the driver first
        # however, we're going to install the drivers *after* possibly enrolling MOK
        # since we shouldn't reboot/shutdown for a few minutes after installing akmod drivers
        # since they'll be compiling in the background!
        # Their recommendations talk about kmod, not akmod, but the process should be the same
        # FIXME needs checking that this actually works.
        if ask-user 'Do you want to enroll MOK and restart afterwards?'; then
            echo-important "Make sure you enroll MOK when you restart."
            
            echo-status "Signing GPU drivers..."
            kmodgenca -a
            mokutil --import /etc/pki/akmods/certs/public_key.der
            
            echo-important "Finished signing GPU drivers."
            systemctl reboot
        fi
    else
        echo-unexpected "UEFI not found; please restart & use UEFI in order to sign drivers..."
    fi

    dnf-install "$INSTALLABLE_NVIDIA_DRIVERS"
    dnf-install "$INSTALLABLE_NVIDIA_UTILS"

    # check arch wiki, these enable DRM
    grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"
    grubby --update-kernel=ALL --args="nvidia-drm.fbdev=1"
    echo-debug "Added modeset & fbdev."

    echo-debug "Regenerating akmod build..."
    akmods --force && dracut --force --regenerate-all
    echo-debug "Regenerated akmod build."
)

install-media-codecs () (
    echo-status "-------------------INSTALLING CODECS / H/W VIDEO ACCELERATION----------------"

    # based on https://github.com/devangshekhawat/Fedora-39-Post-Install-Guide
    dnf install -y --best --allowerasing gstreamer1-plugins-{bad-\*,good-\*,base}
    dnf install -y --best --allowerasing lame\*
    dnf-install "gstreamer1-plugin-openh264" "gstreamer1-libav"
    dnf-group-install-with-optional "multimedia"

    dnf-install "ffmpeg" "gstreamer-ffmpeg" "ffmpeg-libs" "libva" "libva-utils"
    dnf reinstall -y "/etc/yum.repos.d/fedora-cisco-openh264.repo"
    dnf-install "openh264" "gstreamer1-plugin-openh264" "mozilla-openh264"
)

install-gaming-packages () (
    echo-status "-------------------INSTALLING GAMING PACKAGES----------------"
    dnf-install "$INSTALLABLE_EXTRAS" "$INSTALLABLE_WINE_GE_CUSTOM_PKGS" "$INSTALLABLE_OBS_STUDIO"
    flatpak-install "$INSTALLABLE_EXTRAS_FLATPAK"
    echo-success "Done."
)

install-virtualization-packages () (
    echo-status "-------------------INSTALLING VIRTUALIZATION PACKAGES----------------"
    dnf-install "$INSTALLABLE_VIRTUALIZATION_PACKAGES"
    if is-virtual-machine; then
        dnf-install "virtualbox-guest-additions"
    fi
    usermod -a -G libvirt $REAL_USER
    echo-success "Done."
)

install-dev-tools () (
    echo-status "-------------------INSTALLING DEV TOOLS----------------"
    
    dnf-group-install-with-optional "c-development" "development-tools"
    dnf-install "$INSTALLABLE_DEV_PKGS"

    echo-success "Done."
)

install-sublime-text-editor () (
    echo-status "-------------------INSTALLING SUBLIME TEXT----------------"
    
    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    dnf config-manager addrepo --from-repofile="https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo"
    dnf-install sublime-text

    echo-success "Done."
)

install-visual-studio-code () (
    echo-status "-------------------INSTALLING VISUAL STUDIO CODE----------------"
    # instructions taken from here (official site)
    #  https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    (cat <<-VSC_END
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
VSC_END
    ) > /etc/yum.repos.d/vscode.repo
    dnf check-update
    dnf-install code

    echo-success "Done."
)

install-jetbrains-toolbox () (
    # dependencies, described here
    #  https://github.com/nagygergo/jetbrains-toolbox-install
    echo-status "-------------------INSTALLING JETBRAINS TOOLBOX----------------"
    dnf-install "fuse" "libXtst" "libXrender" "glx-utils" "fontconfig-devel" "gtk3" "tar"

    readonly ARCHIVE_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}'| sed 's/[", ]//g')
    wget -cO "./jetbrains-toolbox.tar.gz" "$ARCHIVE_URL"
    tar -xzf "./jetbrains-toolbox.tar.gz" -C "$REAL_USER_HOME/jetbrains-toolbox" --strip-components=1
    rm "./jetbrains-toolbox.tar.gz"
    
    chmod a+x "$REAL_USER_HOME/jetbrains-toolbox"
    mv "$REAL_USER_HOME/jetbrains-toolbox" "/usr/bin/jetbrains-toolbox"
)

configure-system-defaults () (
    echo-status "-------------------SETTING UP SYSTEM DEFAULTS----------------"
    lower-swappiness
    echo-success "Lowered swappiness."
    raise-user-watches
    echo-success "Raised user watches."
    cap-nproc-count
    echo-success "Capped maximum number of processes."
    cap-max-logins-system
    echo-success "Capped max system logins."
    create-convenience-sudoers
    echo-success "Created sudoers.d convenience defaults."

    echo-success "Done."
)

create-swapfile () (
    # if we haven't created /swapfile, go ahead, otherwise get out
    [[ -n $(cat /etc/fstab | grep "/swapfile swap swap defaults 0 0") ]] && return
    [[ -n $(cat /etc/fstab | grep "/swapfile none swap defaults 0 0") ]] && return
    
    echo-status "-------------------CREATING /swapfile----------------"
    # btrfs specific no copy-on-write
    # https://unix.stackexchange.com/questions/599949/swapfile-swapon-invalid-argument
    if is-btrfs-rootfs; then
        truncate -s 0 /swapfile
        chattr +C /swapfile
    fi
    
    kbs=$(cat /proc/meminfo | grep MemTotal | grep -E -o "[0-9]+") 
    dd if=/dev/zero of=/swapfile bs=1KB count=$kbs
    chmod 600 /swapfile 
    chown root /swapfile 
    mkswap /swapfile
    swapon /swapfile
    
    # btrfs specific fstab entry
    if is-btrfs-rootfs; then
        echo "/swapfile none swap defaults 0 0" >> /etc/fstab
        return
    fi
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    
    echo-success "Done."
)

modify-grub () (
    # if we haven't modified GRUB already, go ahead, otherwise get out
    readonly DEFAULT_GRUB_CFG="/etc/default/grub"
    [[ -n $(cat $DEFAULT_GRUB_CFG | grep "GRUB_HIDDEN_TIMEOUT") ]] && return 
    
    echo-status "-------------------MODIFYING GRUB----------------"
    dnf-install "hwinfo"
    out="$(sed -r 's/GRUB_TERMINAL_OUTPUT=.+/GRUB_TERMINAL_OUTPUT="gfxterm"/' < $DEFAULT_GRUB_CFG)" 
    echo "$out" | dd of="$DEFAULT_GRUB_CFG"
    
    echo 'GRUB_HIDDEN_TIMEOUT=0' >> /etc/default/grub
    echo 'GRUB_HIDDEN_TIMEOUT_QUIET=true' >> /etc/default/grub
    echo 'GRUB_GFXPAYLOAD_LINUX=keep' >> /etc/default/grub
    top_res="$(hwinfo --framebuffer | tail -n 2 | grep -E -o '[0-9]{3,4}x[0-9]{3,4}')"
    top_dep="$(hwinfo --framebuffer | tail -n 2 | grep Mode | grep -E -o ', [0-9]{2} bits' | grep -E -o '[0-9]{2}')"
    echo "GRUB_GFXMODE=$top_res x $top_dep" | tr -d ' ' >> /etc/default/grub
    
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

    readonly GRUB_OUT_LOCATION="$(locate grub.cfg | grep /boot | head -n 1)"
    [[ -n $GRUB_OUT_LOCATION ]] && grub2-mkconfig --output="$GRUB_OUT_LOCATION"
    
    echo-success "Done."
)

tweak-minor-details () (
    echo-status "-------------------TWEAKING MINOR DETAILS----------------"
    # https://github.com/tommytran732/Linux-Setup-Scripts/blob/main/Fedora-Workstation-36.sh
    systemctl enable fstrim.timer
    echo-debug "Enabled fs trim timer."
    timedatectl set-local-rtc '0' # for fixing dual boot time inconsistencies
    echo-debug "Set local rtc to 0."
    hostnamectl hostname "$DISTRIBUTION_NAME"
    echo-debug "Updated hostname."
    # if the statement below doesnt work, check this out
    #  https://old.reddit.com/r/linuxhardware/comments/ng166t/s3_deep_sleep_not_working/
    # stop network manager from waiting until online, improves boot times
    systemctl disable NetworkManager-wait-online.service
    echo-debug "Disabled NetworkManager-wait-online.service"
    # if GNOME, stop Software from autostarting & updating in the background, no reason
    is-gnome-session && rm /etc/xdg/autostart/org.gnome.Software.desktop 2> /dev/null
    
    echo-success "Done."
)

configure-ssh-defaults () (
    # if the directory already exists, abandon
    [[ -d "$REAL_USER_HOME/.ssh" ]] && return
    
    echo-status "-------------------GENERATING SSH KEY----------------"
    mkdir -p "$REAL_USER_HOME/.ssh"
    ssh-keygen -q -t ed25519 -N '' -C "$REAL_USER@$DISTRIBUTION_NAME" -f "$REAL_USER_HOME/.ssh/id_ed25519" -P "" <<< $'\ny' >/dev/null 2>&1
    cat "$REAL_USER_HOME/.ssh/id_ed25519.pub"
    # this is REQUIRED for ssh related thingies; key must NOT be readable by anyone else but this user
    chown "$REAL_USER" "$REAL_USER_HOME/.ssh/id_ed25519"
    chmod 700 "$REAL_USER_HOME/.ssh/id_ed25519"
    echo-success "Done."
)

####################################################################################################### 

readonly DISTRIBUTION_NAME="fedora$(rpm -E %fedora)"

#######################################################################################################

readonly INSTALLABLE_ESSENTIAL_DESKTOP_PACKAGES="\
ssh \
glx-utils \
mesa-dri-drivers \
mesa-vulkan-drivers \
plymouth \
plymouth-system-theme \
power-profiles-daemon \
power-profiles-daemon-docs \
"

#######################################################################################################

readonly INSTALLABLE_GNOME_ESSENTIAL_PACKAGES="\
gdm \
gnome-shell \
gnome-session \
gnome-session-wayland-session \
gnome-keyring \
gnome-keyring-pam \
gnome-power-manager \
xdg-desktop-portal-gnome \
NetworkManager-ssh-gnome \
NetworkManager-adsl \
NetworkManager-bluetooth \
NetworkManager-iodine-gnome \
NetworkManager-l2tp-gnome \
NetworkManager-libreswan-gnome \
NetworkManager-openconnect-gnome \
NetworkManager-openvpn-gnome \
NetworkManager-ppp \
NetworkManager-pptp-gnome \
NetworkManager-vpnc-gnome \
NetworkManager-wifi \
NetworkManager-wwan \
gnome-bluetooth \
gnome-bluetooth-libs \
gnome-settings-daemon \
gnome-browser-connector \
gnome-logs \
"

readonly INSTALLABLE_GNOME_APPLICATION_PACKAGES="\
alacritty \
nautilus \
gnome-disk-utility \
gnome-text-editor \
"

readonly INSTALLABLE_ADWAITA_PACKAGES="\
adwaita-icon-theme \
adwaita-cursor-theme \
adwaita-gtk2-theme \
adw-gtk3-theme \
adwaita-qt5 \
qadwaitadecorations-qt5 \
qadwaitadecorations-qt6 \
adwaita-qt6 \
"

readonly INSTALLABLE_GNOME_FLATPAKS="\
net.nokyan.Resources \
de.haeckerfelix.Fragments \
org.gnome.Snapshot \
"

readonly INSTALLABLE_GNOME_EXTENSIONS="\
gnome-extensions-app \
gnome-shell-extension-places-menu \
gnome-shell-extension-forge \
gnome-shell-extension-appindicator \
"

#######################################################################################################

readonly INSTALLABLE_CINNAMON_ESSENTIAL_PACKAGES="\
lightdm-settings \
slick-greeter \
slick-greeter-cinnamon \
cinnamon \
cinnamon-desktop \
cinnamon-screensaver \
cinnamon-session \
cinnamon-settings-daemon \
cinnamon-control-center \
NetworkManager-adsl \
NetworkManager-bluetooth \
NetworkManager-iodine-gnome \
NetworkManager-l2tp-gnome \
NetworkManager-libreswan-gnome \
NetworkManager-openconnect-gnome \
NetworkManager-openvpn-gnome \
NetworkManager-ppp \
NetworkManager-pptp-gnome \
NetworkManager-vpnc-gnome \
NetworkManager-wifi \
NetworkManager-wwan \
"

readonly INSTALLABLE_CINNAMON_APPLICATION_PACKAGES="\
alacritty \
eom \
nemo \
gnome-text-editor \
qbittorrent \
cinnamon-calendar-server \
cinnamon-control-center-filesystem \
gnome-disk-utility \
"

readonly INSTALLABLE_CINNAMON_FLATPAKS="\
net.nokyan.Resources \
"

readonly INSTALLABLE_CINNAMON_EXTENSIONS="\
f$(rpm -E %fedora)-backgrounds-gnome \
f$(rpm -E %fedora)-backgrounds-extras-gnome \
"

#######################################################################################################

# replace grub2 with systemd-boot when we get rid of all the issues
#  regarding proprietary NVIDIA Drivers, and signing them for UEFI
#  apparently, this is the way going forward with unified kernel image
#  https://fedoraproject.org/wiki/Changes/Unified_Kernel_Support_Phase_2
#  so we eon't replace it manually, it'll be replaced be Red Hat themselves
# TODO add systemd-bsod when it becomes available on fedora
readonly INSTALLABLE_ESSENTIAL_PACKAGES="\
setroubleshoot \
setroubleshoot-plugins \
openvpn \
openssl \
python3-cairo \
"

readonly INSTALLABLE_PIPEWIRE_PACKAGES="\
pipewire \
pipewire-alsa \
pipewire-codec-aptx \
pipewire-gstreamer \
pipewire-libs \
pipewire-pulseaudio \
pipewire-utils \
wireplumber \
wireplumber-libs \
"

readonly INSTALLABLE_APPLICATION_PACKAGES="\
firefox \
chromium \
fedora-chromium-config \
flameshot \
gimp \
krita \
evince \
libreoffice \
sqlitebrowser \
piper \
pulseeffects \
"

readonly INSTALLABLE_FLATPAKS="\
com.spotify.Client \
com.github.rafostar.Clapper \
net.cozic.joplin_desktop \
io.gitlab.theevilskeleton.Upscaler \
com.github.tchx84.Flatseal \
"

readonly INSTALLABLE_BTRFS_TOOLS="\
btrfs-assistant \
timeshift \
"

readonly INSTALLABLE_NVIDIA_DRIVERS="\
gcc \
kernel-headers \
kernel-devel \
akmod-nvidia \
xorg-x11-drv-nvidia \
xorg-x11-drv-nvidia-libs \
xorg-x11-drv-nvidia-cuda \
xorg-x11-drv-nvidia-power \
nvidia-gpu-firmware \
nvidia-modprobe \
"

readonly INSTALLABLE_NVIDIA_UTILS="\
nvidia-settings \
"

readonly INSTALLABLE_PWR_MGMNT="\
tlp \
tlp-rdw \
powertop \
"

readonly INSTALLABLE_EXTRAS="\
steam \
gamescope \
"

readonly INSTALLABLE_WINE_GE_CUSTOM_PKGS="\
wine \
vulkan \
winetricks \
protontricks \
vulkan-loader \
vulkan-loader.i686 \
"

readonly INSTALLABLE_OBS_STUDIO="\
obs-studio \
obs-studio-plugin-vkcapture \
obs-studio-plugin-vlc-video \
obs-studio-plugin-webkitgtk \
obs-studio-plugin-x264 \
"

readonly INSTALLABLE_EXTRAS_FLATPAK="\
com.discordapp.Discord \
"

readonly INSTALLABLE_VIRTUALIZATION_PACKAGES="\
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
qemu-audio-pipewire \
"

readonly INSTALLABLE_DEV_PKGS="\
git \
gcc \
clang \
vulkan \
meson \
curl \
cmake \
ninja-build \
java-latest-openjdk \
java-latest-openjdk-devel \
tldr \
info \
"

# NOTE: these are global and should be treated as desktop agnostic
readonly UNINSTALLABLE_BLOAT="\
rhythmbox \
totem \
cheese \
gnome-tour \
gnome-weather \
gnome-terminal \
gnome-software \
gnome-system-monitor \
gnome-remote-desktop \
gnome-font-viewer \
gnome-characters \
gnome-classic-session \
gnome-initial-setup \
gnome-boxes \
gnome-calculator \
gnome-contacts \
gnome-maps \
gnome-clocks \
gnome-connections \
gnome-shell-extension-gamemode \
gnome-shell-extension-background-logo \
"

#######################################################################################################

# ref: https://askubuntu.com/a/30157/8698
if ! is-root; then
    echo-unexpected "The script needs to be run as root." >&2
    exit 2
fi

if ! ping -q -c 1 -W 1 google.com > /dev/null; then
    echo-unexpected "Network connection was not detected."
    echo-unexpected "This script needs network connectivity to continue."
    exit 1
fi

# improve dnf performance
copy-dnf

# for some reason this repository is added on every new install, it's NOT needed since we use toolbox
dnf copr remove -y --skip-broken phracek/PyCharm 2> /dev/null
dnf-install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" # free rpmfusion
dnf-install "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" # nonfree rpmfusion

# no requirement to add flathub ourselves anymore in f38; it should be enabled by default. however, it may not be, most likely by accident, so this is a failsafe
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2> /dev/null
flatpak remote-delete fedora 2> /dev/null
flatpak remote-delete fedora-testing 2> /dev/null

dnf-update-refresh

#######################################################################################################

# TODO when Cosmic DE comes out, I want to test it out, add it here
# declare desktop environment installers
dei=(
install-gnome-essentials
install-cinnamon-essentials
exit
)

# if there's no desktop environment running...
if [[ -z $XDG_CURRENT_DESKTOP ]]; then
    echo-important "After installation of a desktop environment finishes, the system will immediately reboot."
    echo-important "You will need to re-run this script afterwards to complete the setup."
    choice=$(ask-user-multiple-choice "${dei[@]}" )
    # run installer ...
    ${dei[$choice]}
    
    echo-important "Making sure we're booting into a DE next time we boot..."
    systemctl set-default graphical.target
    
    systemctl reboot
fi

if [[ -z $XDG_CURRENT_DESKTOP || -z $XDG_RUNTIME_DIR || -z $XDG_DATA_DIRS || -z $DBUS_SESSION_BUS_ADDRESS ]]; then
    echo-unexpected "The following environment variables must be set for this script to work:"
    echo-unexpected "\$XDG_CURRENT_DESKTOP ($XDG_CURRENT_DESKTOP), \$XDG_RUNTIME_DIR ($XDG_RUNTIME_DIR), \$XDG_DATA_DIRS ($XDG_DATA_DIRS), \$DBUS_SESSION_BUS_ADDRESS ($DBUS_SESSION_BUS_ADDRESS)"
    echo-unexpected "Check the shebang for more information on how to correctly run this script."
    exit 2
fi

# we need this to be up-to-date for some commands
updatedb 2> /dev/null
if [[ ! $? -eq 0 ]]; then
    echo-unexpected "updatedb errored, retrying with absolute path"
    /usr/sbin/updatedb
fi

#######################################################################################################
# user options here, ask most of the stuff ahead of time.

echo-important "You will be asked a series of questions ahead of time, so you can go semi-AFK while installing."
echo-important "Note that NVIDIA drivers require manual confirmation for MOK enrollment, and this cannot be automated"
echo-important " due to its intrusive nature."

ask-user 'Do you want to install virtualization packages?' && INSTALL_VIRTUALIZATION="yes"
ask-user 'Do you want to install gaming packages?' && INSTALL_GAMING="yes"

ask-user 'Do you want to install development tools?' && INSTALL_DEV_TOOLS="yes"
ask-user 'Do you want to install JetBrains Toolbox?' && INSTALL_JETBRAINS="yes"
ask-user 'Do you want to install Visual Studio Code?' && INSTALL_VSC="yes"
ask-user 'Do you want to install Sublime Text Editor?' && INSTALL_SUBLIME="yes"
ask-user 'Do you want to install zeno/scrcpy?' && INSTALL_SCRCPY="yes"

#######################################################################################################

dnf5-remove "$UNINSTALLABLE_BLOAT"

install-universal-necessities
install-media-codecs
install-proprietary-nvidia-drivers
optimize-hardware
optimize-laptop-battery

configure-system-defaults
create-swapfile
modify-grub
tweak-minor-details
configure-ssh-defaults

#######################################################################################################
# user-submitted opts

[[ -n "$INSTALL_VIRTUALIZATION" ]] && install-virtualization-packages
[[ -n "$INSTALL_GAMING" ]] && install-gaming-packages
[[ -n "$INSTALL_DEV_TOOLS" ]] && install-dev-tools
[[ -n "$INSTALL_JETBRAINS" ]] && install-jetbrains-toolbox
[[ -n "$INSTALL_VSC" ]] && install-visual-studio-code
[[ -n "$INSTALL_SUBLIME" ]] && install-sublime-text-editor
[[ -n "$INSTALL_VSC" ]] && dnf5-remove "gnome-text-editor" "gedit"
[[ -n "$INSTALL_SUBLIME" ]] && dnf5-remove "gnome-text-editor" "gedit"

if [[ -n "$INSTALL_SCRCPY" ]]; then
    echo-status "Installing zeno/scrcpy ..."
    dnf copr enable -y zeno/scrcpy
    dnf-install scrcpy
fi

#######################################################################################################

configure-residual-permissions

echo-important "Make sure to restart your PC after making all the necessary adjustments."
echo-important "Remember to add a permanent mount point for internal storage partitions."

mapfile -t parts < <(blkid -o list | grep --invert-match "crypto_" | grep -i "not mounted" | awk '{ print $1 }')
[[ -n "$parts" ]] && echo-important "--------------------------- POSSIBLE FSTAB PARTITIONS ---------------------------"
for part in "${parts[@]}"; do
    part_name=$(echo $part | tr '/' ' ' | awk '{ print $NF }')
    # 512 size blocks, divided by 2, divided by 1024*1024
    part_size=$(( $(cat /sys/class/block/$part_name/size)/2097152 ))
    # if it's a really small partition, it's probably something like a uefi/bootmenu partition, skip it
    [[ $part_size -lt 2 ]] && continue
    
    echo-important "Found PARTITION $part with SIZE $part_size GB"
    echo-important "Mount with mount --mkdir $part $REAL_USER_HOME/MOUNTPOINT"
    echo-important "FOR REGULAR PARTITIONS add $part to fstab as: "
    echo-important "$part $REAL_USER_HOME/MOUNTPOINT auto rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show,x-gvfs-name=YOUR_NAME_HERE 0 0"
    echo-important "--------"
    echo-important "FOR HOME PARTITIONS add $part to fstab as:"
    echo-important "$part /home/USERNAME auto defaults 0 2"
    echo-important "Then run:"
    echo-important "sudo mount -a && sudo useradd --home /home/USERNAME USERNAME && sudo chown -R USERNAME:USERNAME /home/USERNAME"
    echo-important "---------------------------"
done

echo-success "Done."

#######################################################################################################

if is-gnome-session; then
    echo-important "Personalizing GNOME session..."
    echo-important "Make sure to get the legacy GTK3 Theme Auto Switcher"
    echo-important "https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/"
    
    echo-status "Configuring all gsettings for $REAL_USER . . ."
    # user gsettings using heredocs
    # https://tldp.org/LDP/abs/html/here-docs.html
    sudo --preserve-env="XDG_RUNTIME_DIR" --preserve-env="XDG_DATA_DIRS" --preserve-env="DBUS_SESSION_BUS_ADDRESS" -u "$REAL_USER" bash <<-GSETTINGS_DELIMITER
source "$(dirname -- "$BASH_SOURCE")/common-utils.sh"

# theme settings
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# custom keybinds/shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings '[]'
add-gsettings-shortcut "resource-monitor" "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=resources net.nokyan.Resources" "<Shift><Control>Escape"
add-gsettings-shortcut "flameshot" "/usr/local/bin/flameshot-gui-workaround" "Print"
add-gsettings-shortcut "alacritty" "alacritty" "<Shift><Control>KP_Add"

# extension settings 
gsettings set org.gnome.shell enabled-extensions "['places-menu@gnome-shell-extensions.gcampax.github.com', 'appindicatorsupport@rgcjonas.gmail.com', 'forge@jmmaranan.com']"

gsettings set org.gnome.shell.extensions.forge.keybindings con-split-horizontal "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings con-split-layout-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings con-split-vertical "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings con-stacked-layout-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings con-tabbed-layout-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings con-tabbed-showtab-decoration-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings focus-border-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings mod-mask-mouse-tile 'None'
gsettings set org.gnome.shell.extensions.forge.keybindings prefs-open "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings prefs-tiling-toggle "['<Super>y']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-down "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-up "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-gap-size-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-gap-size-increase "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-down "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-up "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-bottom-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-bottom-increase "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-left-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-left-increase "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-right-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-right-increase "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-top-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-top-decrease "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-top-increase "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-center "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-one-third-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-one-third-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-two-third-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-two-third-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-down "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-last-active "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-up "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-toggle-always-float "['<Super>c']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-toggle-float "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings workspace-active-tile-toggle "[]"
gsettings set org.gnome.shell.extensions.forge primary-layout-mode 'tiling'
gsettings set org.gnome.shell.extensions.forge float-always-on-top-enabled true
gsettings set org.gnome.shell.extensions.forge preview-hint-enabled false
gsettings set org.gnome.shell.extensions.forge auto-split-enabled true
gsettings set org.gnome.shell.extensions.forge focus-border-toggle false
gsettings set org.gnome.shell.extensions.forge split-border-toggle false
gsettings set org.gnome.shell.extensions.forge move-pointer-focus-enabled false
gsettings set org.gnome.shell.extensions.forge stacked-tiling-mode-enabled true
gsettings set org.gnome.shell.extensions.forge tabbed-tiling-mode-enabled false
gsettings set org.gnome.shell.extensions.forge tiling-mode-enabled true
gsettings set org.gnome.shell.extensions.forge window-gap-hidden-on-single true
gsettings set org.gnome.shell.extensions.forge window-gap-size 1
gsettings set org.gnome.shell.extensions.forge window-gap-size-increment 1
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-cpu true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-drive-read-speed false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-drive-read-total false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-drive-write-speed false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-drive-write-total false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources apps-show-memory true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources base 'Decimal'
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources is-maximized false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources network-bits false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-cpu true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-drive-read-speed true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-drive-read-total false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-drive-write-speed true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-drive-write-total false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-id true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-memory true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources processes-show-user true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources refresh-speed 'Normal'
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources show-logical-cpus true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources show-search-on-start true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources show-virtual-drives true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources show-virtual-network-interfaces false
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources sidebar-details true
flatpak run --branch=stable --arch=x86_64 --command=gsettings net.nokyan.Resources set net.nokyan.Resources temperature-unit 'Celsius'

# nautilus & gtk3/gtk4 filechooser settings
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

# functional wm settings
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'none'
gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'menu'
gsettings set org.gnome.desktop.wm.preferences auto-raise false
gsettings set org.gnome.desktop.wm.preferences auto-raise-delay 500
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'
gsettings set org.gnome.desktop.wm.preferences disable-workarounds false
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences focus-new-windows 'smart'
gsettings set org.gnome.desktop.wm.preferences raise-on-click true
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button false
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false
gsettings set org.gnome.desktop.interface menubar-detachable false
gsettings set org.gnome.desktop.interface overlay-scrolling true
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.shell.window-switcher current-workspace-only false

# peripheral settings
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state false
gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state false
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
gsettings set org.gnome.desktop.peripherals.mouse double-click 250
gsettings set org.gnome.desktop.peripherals.mouse middle-click-emulation false
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.mouse speed -0.2
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

# privacy settings
gsettings set org.gnome.desktop.media-handling automount true
gsettings set org.gnome.desktop.media-handling automount-open true
gsettings set org.gnome.desktop.media-handling autorun-never true
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

# disable event sound
gsettings set org.gnome.desktop.sound event-sounds false
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# disable hot corners
gsettings set org.gnome.desktop.interface enable-hot-corners false

# modal & checkalive timeouts
gsettings set org.gnome.mutter attach-modal-dialogs true
gsettings set org.gnome.mutter check-alive-timeout 15000

# night light settings
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 6.0

# keybinds/shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute "[]"
gsettings set org.gnome.shell.keybindings screenshot "[]"
gsettings set org.gnome.shell.keybindings screenshot-window "[]"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['Menu']"
gsettings set org.gnome.desktop.wm.keybindings always-on-top  "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-move  "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-resize  "[]"
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
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
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]"
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
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-group "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward  "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-panels "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Control>Home']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control>End']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings toggle-above "[]"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "[]"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>x']"
gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces "[]"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
gsettings set org.gnome.desktop.wm.preferences workspace-names  "[]"

exit
GSETTINGS_DELIMITER
    echo-success "Done."
fi

# write everything to disk to prevent unpredictable behaviour
#  this might not be needed, but better to be explicit than implicit
sync
