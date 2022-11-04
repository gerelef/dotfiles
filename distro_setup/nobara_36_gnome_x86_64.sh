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

GDBUS_ACTIVATABLE_EXTENSIONS="\
dash-to-panel@jderose9.github.com \
pop-shell@system76.com \
places-menu@gnome-shell-extensions.gcampax.github.com \
appindicatorsupport@rgcjonas.gmail.com \
sound-output-device-chooser@kgshank.net \
freon@UshakovVasilii_Github.yahoo.com \
nightthemeswitcher@romainvigier.fr \
"

GDBUS_ACTIVATABLE_EXTENSIONS_ARR=( \
"dash-to-panel@jderose9.github.com" \
"pop-shell@system76.com" \
"places-menu@gnome-shell-extensions.gcampax.github.com" \
"appindicatorsupport@rgcjonas.gmail.com" \
"sound-output-device-chooser@kgshank.net" \
"freon@UshakovVasilii_Github.yahoo.com" \
"nightthemeswitcher@romainvigier.fr" \
)

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
#dnf update -y 
echo "Finished updating system"

echo "-------------------INSTALLING---------------- $INSTALLABLE_PACKAGES" | tr " " "\n"
#dnf install -y $INSTALLABLE_PACKAGES 

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
dnf group info "Development Tools"
read -p "Are you sure you want to install Development Tools?[Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
#    dnf groupinstall -y "Development Tools" 
    echo "Finished installing Development Tools"
fi

echo "Switching to $REAL_USER to install flatpaks"
echo "-------------------INSTALLING---------------- $INSTALLABLE_FLATPAKS" | tr " " "\n"
#su - $REAL_USER -c "flatpak install --user -y $INSTALLABLE_FLATPAKS"
echo "Continuing as $(whoami)"

echo "-------------------INSTALLING---------------- $INSTALLABLE_IDE_FLATPAKS" | tr " " "\n"
read -p "Are you sure you want to install Community IDEs?[Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
#    su - $REAL_USER -c "flatpak install --user -y $INSTALLABLE_IDE_FLATPAKS"
    echo "Finished installing IDEs"
fi

echo "-------------------INSTALLING---------------- $INSTALLABLE_EXTENSIONS" | tr " " "\n"
echo "With gbus, extensions will be directly downloaded from gnome-extensions website."
echo "However, compatibility is not guaranteed."
echo "With dnf, it's much more likely the extension will work."
read -p "Do you want to install extensions from gdbus/dnf/none?[0/1/n] " -n 1 -r
echo ""
if ! [[ $REPLY =~ ^[Nn]$ ]]; then
    if [[ $REPLY =~ ^[0]$ ]]; then
        echo ""
        for ext in ${GDBUS_ACTIVATABLE_EXTENSIONS_ARR[@]}; do
            echo "Installing $ext"
            gdbus call --timeout 60 \
                --session \
                --dest org.gnome.Shell.Extensions \
                --object-path /org/gnome/Shell/Extensions \
                --method org.gnome.Shell.Extensions.InstallRemoteExtension "$ext"
        done
    elif [[ $REPLY =~ ^[1]$ ]]; then
         echo "DEBUG THINGY LOL"
#        dnf install -y $INSTALLABLE_EXTENSIONS 
    fi
    echo "Finished installing"
fi

echo "-------------------GSETTINGS----------------"
################################### GSETTINGS ###################################
gsettings set com.mattjakeman.ExtensionManager sort-enabled-first true
gsettings set org.gnome.TextEditor auto-indent true
gsettings set org.gnome.TextEditor highlight-current-line true
gsettings set org.gnome.TextEditor indent-style 'space'
gsettings set org.gnome.TextEditor restore-session true
gsettings set org.gnome.TextEditor right-margin-position 80
gsettings set org.gnome.TextEditor show-line-numbers true
gsettings set org.gnome.TextEditor show-map true
gsettings set org.gnome.TextEditor spellcheck false
gsettings set org.gnome.TextEditor style-scheme 'classic'
gsettings set org.gnome.TextEditor tab-width 4
gsettings set org.gnome.TextEditor use-system-font true
gsettings set org.gnome.TextEditor wrap-text true
gsettings set org.gnome.desktop.a11y always-show-universal-access-status false
gsettings set org.gnome.desktop.a11y.mouse click-type-window-visible true
gsettings set org.gnome.desktop.a11y.mouse secondary-click-enabled false
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.gnome.desktop.calendar show-weekdate false
gsettings set org.gnome.desktop.datetime automatic-timezone true
gsettings set org.gnome.desktop.default-applications.terminal exec "alacritty"
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "--config-file /home/$REAL_USER/dotfiles/rc/alacritty.yml"
gsettings set org.gnome.desktop.input-sources show-all-sources false
gsettings set org.gnome.desktop.input-sources per-window false
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
gsettings set org.gnome.desktop.notifications show-banners true
gsettings set org.gnome.desktop.notifications show-in-lock-screen true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state false
gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true
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
gsettings set org.gnome.desktop.remote-desktop.rdp enable false
gsettings set org.gnome.desktop.screensaver color-shading-type 'solid'
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent false
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu ['Menu']
gsettings set org.gnome.desktop.wm.keybindings always-on-top @as []
gsettings set org.gnome.desktop.wm.keybindings begin-move @as []
gsettings set org.gnome.desktop.wm.keybindings begin-resize @as []
gsettings set org.gnome.desktop.wm.keybindings close ['<Super>d']
gsettings set org.gnome.desktop.wm.keybindings cycle-group ['<Alt>grave']
gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward ['<Shift><Alt>grave']
gsettings set org.gnome.desktop.wm.keybindings cycle-panels @as []
gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward @as []
gsettings set org.gnome.desktop.wm.keybindings cycle-windows @as []
gsettings set org.gnome.desktop.wm.keybindings cycle-windows-backward @as []
gsettings set org.gnome.desktop.wm.keybindings lower @as []
gsettings set org.gnome.desktop.wm.keybindings maximize @as []
gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally @as []
gsettings set org.gnome.desktop.wm.keybindings maximize-vertically @as []
gsettings set org.gnome.desktop.wm.keybindings minimize ['<Super>z']
gsettings set org.gnome.desktop.wm.keybindings move-to-center @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-side-n @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-side-s @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 ['<Super><Shift>Home']
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-11 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-12 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last @as []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left ['<Shift><Control>Home']
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right ['<Shift><Control>End']
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up @as []
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu @as []
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog ['<Alt>F2']
gsettings set org.gnome.desktop.wm.keybindings raise @as []
gsettings set org.gnome.desktop.wm.keybindings raise-or-lower @as []
gsettings set org.gnome.desktop.wm.keybindings set-spew-mark @as []
gsettings set org.gnome.desktop.wm.keybindings show-desktop @as []
gsettings set org.gnome.desktop.wm.keybindings switch-applications ['<Alt>Tab']
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward ['<Shift><Alt>Tab']
gsettings set org.gnome.desktop.wm.keybindings switch-group @as []
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward @as []
gsettings set org.gnome.desktop.wm.keybindings switch-input-source ['<Super>space']
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward ['<Shift><Super>space']
gsettings set org.gnome.desktop.wm.keybindings switch-panels @as []
gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down ['<Primary><Super>Down', '<Primary><Super>j']
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last @as []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left ['<Control>Home']
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right ['<Control>End']
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up ['<Primary><Super>Up', '<Primary><Super>k']
gsettings set org.gnome.desktop.wm.keybindings switch-windows @as []
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward @as []
gsettings set org.gnome.desktop.wm.keybindings toggle-above @as []
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen @as []
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized ['<Super>x']
gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces @as []
gsettings set org.gnome.desktop.wm.keybindings toggle-shaded @as []
gsettings set org.gnome.desktop.wm.keybindings unmaximize @as []
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'none'
gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'menu'
gsettings set org.gnome.desktop.wm.preferences audible-bell true
gsettings set org.gnome.desktop.wm.preferences auto-raise false
gsettings set org.gnome.desktop.wm.preferences auto-raise-delay 500
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'
gsettings set org.gnome.desktop.wm.preferences disable-workarounds false
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences focus-new-windows 'smart'
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
gsettings set org.gnome.desktop.wm.preferences raise-on-click true
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button false
gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Light 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font true
gsettings set org.gnome.desktop.wm.preferences visual-bell false
gsettings set org.gnome.desktop.wm.preferences visual-bell-type 'fullscreen-flash'
gsettings set org.gnome.desktop.wm.preferences workspace-names @as []
gsettings set org.gnome.gedit.plugins active-plugins ['spell', 'sort', 'quickhighlight', 'openlinks', 'modelines', 'filebrowser', 'docinfo']
gsettings set org.gnome.gedit.plugins.drawspaces draw-spaces ['space', 'tab', 'leading', 'text', 'trailing']
gsettings set org.gnome.gedit.plugins.drawspaces show-white-space true
gsettings set org.gnome.gedit.plugins.externaltools font 'Monospace 10'
gsettings set org.gnome.gedit.plugins.externaltools use-system-font true
gsettings set org.gnome.gedit.plugins.filebrowser binary-patterns ['*.la', '*.lo']
gsettings set org.gnome.gedit.plugins.filebrowser enable-remote false
gsettings set org.gnome.gedit.plugins.filebrowser filter-mode ['hide-hidden', 'hide-binary']
gsettings set org.gnome.gedit.plugins.filebrowser filter-pattern ''
gsettings set org.gnome.gedit.plugins.filebrowser open-at-first-doc true
gsettings set org.gnome.gedit.plugins.filebrowser root 'file:///'
gsettings set org.gnome.gedit.plugins.filebrowser tree-view true
gsettings set org.gnome.gedit.plugins.filebrowser virtual-root 'file:///home/cerberus/dotfiles/distro_setup'
gsettings set org.gnome.gedit.plugins.filebrowser.nautilus click-policy 'double'
gsettings set org.gnome.gedit.plugins.filebrowser.nautilus confirm-trash true
gsettings set org.gnome.gedit.plugins.pythonconsole command-color '#314e6c'
gsettings set org.gnome.gedit.plugins.pythonconsole error-color '#990000'
gsettings set org.gnome.gedit.plugins.pythonconsole font 'Monospace 10'
gsettings set org.gnome.gedit.plugins.pythonconsole use-system-font true
gsettings set org.gnome.gedit.plugins.spell highlight-misspelled false
gsettings set org.gnome.gedit.plugins.time custom-format '%d/%m/%Y %H:%M:%S'
gsettings set org.gnome.gedit.plugins.time prompt-type 'prompt-selected-format'
gsettings set org.gnome.gedit.plugins.time selected-format '%c'
gsettings set org.gnome.gedit.plugins.translate apertium-server 'https://www.apertium.org/apy'
gsettings set org.gnome.gedit.plugins.translate api-key ''
gsettings set org.gnome.gedit.plugins.translate language-pair 'eng|spa'
gsettings set org.gnome.gedit.plugins.translate output-to-document true
gsettings set org.gnome.gedit.plugins.translate service 0
gsettings set org.gnome.gedit.plugins.wordcompletion interactive-completion true
gsettings set org.gnome.gedit.plugins.wordcompletion minimum-word-size 2
gsettings set org.gnome.gedit.preferences.editor auto-indent true
gsettings set org.gnome.gedit.preferences.editor auto-save false
gsettings set org.gnome.gedit.preferences.editor auto-save-interval 10
gsettings set org.gnome.gedit.preferences.editor background-pattern 'none'
gsettings set org.gnome.gedit.preferences.editor bracket-matching true
gsettings set org.gnome.gedit.preferences.editor create-backup-copy false
gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
gsettings set org.gnome.gedit.preferences.editor display-overview-map false
gsettings set org.gnome.gedit.preferences.editor display-right-margin true
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
gsettings set org.gnome.gedit.preferences.editor ensure-trailing-newline true
gsettings set org.gnome.gedit.preferences.editor highlight-current-line false
gsettings set org.gnome.gedit.preferences.editor insert-spaces true
gsettings set org.gnome.gedit.preferences.editor max-undo-actions 2000
gsettings set org.gnome.gedit.preferences.editor restore-cursor-position true
gsettings set org.gnome.gedit.preferences.editor right-margin-position 180
gsettings set org.gnome.gedit.preferences.editor scheme 'oblivion'
gsettings set org.gnome.gedit.preferences.editor search-highlighting true
gsettings set org.gnome.gedit.preferences.editor smart-home-end 'after'
gsettings set org.gnome.gedit.preferences.editor syntax-highlighting true
gsettings set org.gnome.gedit.preferences.editor tabs-size 4
gsettings set org.gnome.gedit.preferences.editor use-default-font true
gsettings set org.gnome.gedit.preferences.editor wrap-last-split-mode 'word'
gsettings set org.gnome.gedit.preferences.editor wrap-mode 'none'
gsettings set org.gnome.gedit.preferences.encodings candidate-encodings ['']
gsettings set org.gnome.gedit.preferences.print margin-bottom 25.0
gsettings set org.gnome.gedit.preferences.print margin-left 25.0
gsettings set org.gnome.gedit.preferences.print margin-right 25.0
gsettings set org.gnome.gedit.preferences.print margin-top 15.0
gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
gsettings set org.gnome.gedit.preferences.print print-font-header-pango 'Sans 11'
gsettings set org.gnome.gedit.preferences.print print-font-numbers-pango 'Sans 8'
gsettings set org.gnome.gedit.preferences.print print-header true
gsettings set org.gnome.gedit.preferences.print print-line-numbers 0
gsettings set org.gnome.gedit.preferences.print print-syntax-highlighting true
gsettings set org.gnome.gedit.preferences.print print-wrap-mode 'word'
gsettings set org.gnome.gedit.preferences.ui bottom-panel-visible false
gsettings set org.gnome.gedit.preferences.ui show-tabs-mode 'auto'
gsettings set org.gnome.gedit.preferences.ui side-panel-visible false
gsettings set org.gnome.gedit.preferences.ui statusbar-visible true
gsettings set org.gnome.gedit.state.file-chooser open-recent true
gsettings set org.gnome.mutter attach-modal-dialogs true
gsettings set org.gnome.mutter auto-maximize true
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.mutter check-alive-timeout 15000
gsettings set org.gnome.nautilus.compression default-compression-format 'tar.xz'
gsettings set org.gnome.nautilus.icon-view captions ['date_modified_with_time', 'permissions']
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'
gsettings set org.gnome.nautilus.list-view default-visible-columns ['name', 'date_modified_with_time', 'permissions', 'size']
gsettings set org.gnome.nautilus.preferences click-policy 'double'
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.preferences search-filter-time-type 'last_modified'
gsettings set org.gnome.nautilus.preferences search-view 'list-view'
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.preferences show-delete-permanently false
gsettings set org.gnome.nautilus.preferences show-directory-item-counts 'local-only'
gsettings set org.gnome.nautilus.preferences tabs-open-position 'after-current-tab'
gsettings set org.gnome.nautilus.preferences enable-interactive-search false
gsettings set org.gnome.nautilus.window-state sidebar-width 150
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 6.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2700
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled true
gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 30
gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
gsettings set org.gnome.shell development-tools true
gsettings set org.gnome.shell disable-extension-version-validation false
gsettings set org.gnome.shell disable-user-extensions false
gsettings set org.gnome.shell.extensions.appindicator icon-contrast 0.0
gsettings set org.gnome.shell.extensions.appindicator icon-opacity 255
gsettings set org.gnome.shell.extensions.appindicator icon-size 0
gsettings set org.gnome.shell.extensions.appindicator icon-spacing 12
gsettings set org.gnome.shell.extensions.appindicator tray-order 1
gsettings set org.gnome.shell.extensions.appindicator tray-pos 'right'
gsettings set org.gnome.shell.extensions.pop-shell activate-launcher []
gsettings set org.gnome.shell.extensions.pop-shell active-hint true
gsettings set org.gnome.shell.extensions.pop-shell column-size 64
gsettings set org.gnome.shell.extensions.pop-shell focus-down ['<Super>Down', '<Super>KP_Down', '<Super>j']
gsettings set org.gnome.shell.extensions.pop-shell focus-left ['<Super>Left', '<Super>KP_Left', '<Super>h']
gsettings set org.gnome.shell.extensions.pop-shell focus-right ['<Super>Right', '<Super>KP_Right', '<Super>l']
gsettings set org.gnome.shell.extensions.pop-shell focus-up ['<Super>Up', '<Super>KP_Up', '<Super>k']
gsettings set org.gnome.shell.extensions.pop-shell gap-inner 0
gsettings set org.gnome.shell.extensions.pop-shell gap-outer 0
gsettings set org.gnome.shell.extensions.pop-shell hint-color-rgba 'rgba(0,114,198,0.195946)'
gsettings set org.gnome.shell.extensions.pop-shell log-level 1
gsettings set org.gnome.shell.extensions.pop-shell management-orientation ['o']
gsettings set org.gnome.shell.extensions.pop-shell pop-monitor-down ['<Super><Shift><Primary>Down', '<Super><Shift><Primary>KP_Down', '<Super><Shift><Primary>j']
gsettings set org.gnome.shell.extensions.pop-shell pop-monitor-left ['<Super><Shift>Left', '<Super><Shift>KP_Left', '<Super><Shift>h']
gsettings set org.gnome.shell.extensions.pop-shell pop-monitor-right ['<Super><Shift>Right', '<Super><Shift>KP_Right', '<Super><Shift>l']
gsettings set org.gnome.shell.extensions.pop-shell pop-monitor-up ['<Super><Shift><Primary>Up', '<Super><Shift><Primary>KP_Up', '<Super><Shift><Primary>k']
gsettings set org.gnome.shell.extensions.pop-shell pop-workspace-down ['<Super><Shift>Down', '<Super><Shift>KP_Down', '<Super><Shift>j']
gsettings set org.gnome.shell.extensions.pop-shell pop-workspace-up ['<Super><Shift>Up', '<Super><Shift>KP_Up', '<Super><Shift>k']
gsettings set org.gnome.shell.extensions.pop-shell row-size 64
gsettings set org.gnome.shell.extensions.pop-shell show-skip-taskbar true
gsettings set org.gnome.shell.extensions.pop-shell show-title false
gsettings set org.gnome.shell.extensions.pop-shell smart-gaps true
gsettings set org.gnome.shell.extensions.pop-shell snap-to-grid false
gsettings set org.gnome.shell.extensions.pop-shell tile-accept ['Return', 'KP_Enter']
gsettings set org.gnome.shell.extensions.pop-shell tile-by-default true
gsettings set org.gnome.shell.extensions.pop-shell tile-enter ['<Super>Return', '<Super>KP_Enter']
gsettings set org.gnome.shell.extensions.pop-shell tile-move-down ['Down', 'KP_Down', 'j']
gsettings set org.gnome.shell.extensions.pop-shell tile-move-left ['Left', 'KP_Left', 'h']
gsettings set org.gnome.shell.extensions.pop-shell tile-move-right ['Right', 'KP_Right', 'l']
gsettings set org.gnome.shell.extensions.pop-shell tile-move-up ['Up', 'KP_Up', 'k']
gsettings set org.gnome.shell.extensions.pop-shell tile-orientation ['<Super>o']
gsettings set org.gnome.shell.extensions.pop-shell tile-reject ['Escape']
gsettings set org.gnome.shell.extensions.pop-shell tile-resize-down ['<Shift>Down', '<Shift>KP_Down', '<Shift>j']
gsettings set org.gnome.shell.extensions.pop-shell tile-resize-left ['<Shift>Left', '<Shift>KP_Left', '<Shift>h']
gsettings set org.gnome.shell.extensions.pop-shell tile-resize-right ['<Shift>Right', '<Shift>KP_Right', '<Shift>l']
gsettings set org.gnome.shell.extensions.pop-shell tile-resize-up ['<Shift>Up', '<Shift>KP_Up', '<Shift>k']
gsettings set org.gnome.shell.extensions.pop-shell tile-swap-down ['<Primary>Down', '<Primary>KP_Down', '<Primary>j']
gsettings set org.gnome.shell.extensions.pop-shell tile-swap-left ['<Primary>Left', '<Primary>KP_Left', '<Primary>h']
gsettings set org.gnome.shell.extensions.pop-shell tile-swap-right ['<Primary>Right', '<Primary>KP_Right', '<Primary>l']
gsettings set org.gnome.shell.extensions.pop-shell tile-swap-up ['<Primary>Up', '<Primary>KP_Up', '<Primary>k']
gsettings set org.gnome.shell.extensions.pop-shell toggle-floating ['<Super>g']
gsettings set org.gnome.shell.extensions.pop-shell toggle-stacking ['s']
gsettings set org.gnome.shell.extensions.pop-shell toggle-stacking-global ['<Super>s']
gsettings set org.gnome.shell.extensions.pop-shell toggle-tiling ['<Super>y']
gsettings set org.gnome.shell.keybindings focus-active-notification @as []
gsettings set org.gnome.shell.keybindings open-application-menu @as []
gsettings set org.gnome.shell.keybindings screenshot ['<Shift>Print']
gsettings set org.gnome.shell.keybindings screenshot-window ['<Control>Print']
gsettings set org.gnome.shell.keybindings shift-overview-down @as []
gsettings set org.gnome.shell.keybindings shift-overview-up @as []
gsettings set org.gnome.shell.keybindings show-screen-recording-ui ['<Shift><Control>Print']
gsettings set org.gnome.shell.keybindings show-screenshot-ui ['Print']
gsettings set org.gnome.shell.keybindings switch-to-application-1 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-2 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-3 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-4 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-5 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-6 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-7 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-8 @as []
gsettings set org.gnome.shell.keybindings switch-to-application-9 @as []
gsettings set org.gnome.shell.keybindings toggle-application-view []
gsettings set org.gnome.shell.keybindings toggle-message-tray ['<Super>v']
gsettings set org.gnome.shell.keybindings toggle-overview []
gsettings set org.gnome.shell.overrides attach-modal-dialogs false
gsettings set org.gnome.shell.overrides dynamic-workspaces true
gsettings set org.gnome.shell.overrides edge-tiling true
gsettings set org.gnome.shell.overrides focus-change-on-pointer-rest true
gsettings set org.gnome.shell.overrides workspaces-only-on-primary false
gsettings set org.gnome.shell.weather automatic-location true
gsettings set org.gnome.software allow-updates true
gsettings set org.gnome.software download-updates true
gsettings set org.gnome.software download-updates-notify true
gsettings set org.gnome.software enable-repos-dialog true
gsettings set org.gnome.software show-nonfree-ui true
gsettings set org.gnome.software show-ratings false
gsettings set org.gnome.system.location enabled true
gsettings set org.gnome.system.location max-accuracy-level 'city'
gsettings set org.gtk.Settings.FileChooser clock-format '24h'
gsettings set org.gtk.Settings.FileChooser date-format 'regular'
gsettings set org.gtk.Settings.FileChooser expand-folders false
gsettings set org.gtk.Settings.FileChooser location-mode 'path-bar'
gsettings set org.gtk.Settings.FileChooser show-hidden false
gsettings set org.gtk.Settings.FileChooser show-size-column true
gsettings set org.gtk.Settings.FileChooser show-type-column true
gsettings set org.gtk.Settings.FileChooser sidebar-width 150
gsettings set org.gtk.Settings.FileChooser sort-column 'modified'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser clock-format '24h'
gsettings set org.gtk.gtk4.Settings.FileChooser date-format 'regular'
gsettings set org.gtk.gtk4.Settings.FileChooser expand-folders false
gsettings set org.gtk.gtk4.Settings.FileChooser location-mode 'path-bar'
gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden false
gsettings set org.gtk.gtk4.Settings.FileChooser show-size-column true
gsettings set org.gtk.gtk4.Settings.FileChooser show-type-column true
gsettings set org.gtk.gtk4.Settings.FileChooser sidebar-width 150
gsettings set org.gtk.gtk4.Settings.FileChooser sort-column 'modified'
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
#################################################################################
echo "--------------------------------------------"


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
echo "  rw,user,exec,nosuid,nodev,nofail,auto,x-gvfs-show"
echo "Standard fstab ROOT mount arguments:"
echo "  nouser,nosuid,nodev,nofail,x-gvfs-show,x-udisks-auth"
echo "---------------------------------------------"


systemctl restart NetworkManager
hostnamectl hostname "$DISTRIBUTION_NAME"

updatedb 2> /dev/null
if ! [ $? -eq 0 ]; then
    echo "Couldn't updatedb, retrying with absolute path"
    /usr/sbin/updatedb
fi

