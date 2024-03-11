## setup
This directory contains scripts that are to be used upon initial startup of a standard distribution (indicated by the name), to setup the default configuration appropriate for it.

### naming format
Rules & regex:
```bash
name-version(-de).sh # desktop environment specifier is optional
valid regex: [a-zA-Z0-9]+-[0-9]+(-gnome)?(-kde)?(-cinnamon)?(-hypr)?\.sh
```

### library
`common-utils.sh` is a REQUIRED catch-all "library" script to be used by the aformentioned scripts.

### historical note
Recently, the format used earlier with gsettings/main for the naming was deprecated & removed immediately, due to finally solving the integration issue with XDG, DBUS and running as root.
Since the old scripts were effectively dead, and they are not to be used due to several reasons, I decided against including them in any future versions of this directory. 
You should be able to find them in commit `6d1a96c`.
