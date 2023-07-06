## setup scripts
This directory contains scripts that are to be used upon initial startup of a standard distribution (indicated by the name), to setup the default configuration appropriate for it.
### Naming format
Naming format is as such:
```
name_version_de_arch_[main/gsettings].sh
```
### Descending order, based on recency (most recent at the top):
- `fedora_38_gnome_x86_64_main.sh` / `fedora_38_gnome_x86_64_gsettings.sh`
- `fedora_37_gnome_x86_64_main.sh` / `fedora_37_gnome_x86_64_gsettings.sh`
- `nobara_36_gnome_x86_64_main.sh` / `nobara_36_gnome_x86_64_gsettings.sh`

`common-utils.sh` is a catch-all "library" script to be used by the aformentioned scripts. 

