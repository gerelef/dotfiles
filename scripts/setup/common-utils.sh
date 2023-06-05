#!/usr/bin/env bash

shopt -s globstar
shopt -s dotglob
shopt -s nullglob

dnf-install () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-INSTALL---------------- $*" | tr " " "\n"
    while : ; do
        dnf install -y --best --allowerasing $@ && break
    done
    echo "Finished installing."
)

dnf-install-group () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-GROUP-INSTALL---------------- $*" | tr " " "\n"
    while : ; do
        dnf groupinstall -y --best --allowerasing $@ && break
    done
    echo "Finished group-installing."
)

dnf-update-refresh () (
    echo "-------------------DNF-UPDATE----------------"
    while : ; do
        dnf update -y --refresh && break
    done
    echo "Finished updating."
)

dnf-remove () (
    [[ $# -eq 0 ]] && return 2
    
    echo "-------------------DNF-REMOVE---------------- $*" | tr " " "\n"
    dnf remove -y --skip-broken $@
    echo "Finished removing."
)

flatpak-install () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    echo "-------------------FLATPAK-INSTALL-SYSTEM---------------- $*" | tr " " "\n"
    while : ; do
        su - "$REAL_USER" -c "flatpak install --system -y $@" && break
    done
    echo "Finished flatpak-installing."
)

change-ownership () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown "$REAL_USER" "$@"
    chmod 700 "$@"
)

change-ownership-recursive () (
    [[ $# -eq 0 ]] && return 2
    [[ -z "$REAL_USER" ]] && return 2
    
    chown -R "$REAL_USER" "$@"
    chmod -R 700 "$@"
)
