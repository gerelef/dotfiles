#!/usr/bin/env -S sudo --preserve-env="XDG_CURRENT_DESKTOP" --preserve-env="XDG_RUNTIME_DIR" --preserve-env="XDG_DATA_DIRS" --preserve-env="DBUS_SESSION_BUS_ADDRESS" bash

readonly DIR=$(dirname -- "$BASH_SOURCE")

[[ -f "$DIR/common-utils.sh" ]] || ( echo "$DIR/common-utils.sh doesn't exist! exiting..." && exit 2 )
source "$DIR/common-utils.sh"

# DEPENDENCIES FOR THE CURRENT SCRIPT
dnf-install flatpak curl plocate pciutils udisks2 dnf5

# change dnf4 to dnf5 (preview/unstable: is supposed to be shipped with fedora-41)
update-alternatives --install /usr/bin/dnf dnf /usr/bin/dnf5 1

