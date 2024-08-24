# dotfiles
My personal dotfiles. I do not recommend to anyone seeking inspiration to blindly copy-paste my configs; they WILL introduce problems for you. The contents of each rc file, especially the .bashrc file, have been sourced by a variety of sources, including my personal experience & particularly my preferences.
There is no particular philosophy to these configuration files, it's all personal taste, and adhere to the latest versions of applications I use between platforms, which are, for the most part, running the same OS.
The common `$XDG_CONFIG_HOME` directory setup is semi-emulated, with exceptions for convenience.

## details
- `.shell-requirements` is a requirements-style file for dependencies that are required for these dotfiles to work correctly. The appropriate handling should be done by `require-login-shell-packages` when a shell first runs.
- `.stowconfig` is a configuration file for the `pstow.py` utility under `./scripts/utils/`. The file format should be self-explanatory, however documentation should exist somewhere.
- `scripts/` contain scripts as well as some configuration files. The filenames should be a hint to their usage.
- `.config` contains generic configuration files. The most common `$XDG_CONFIG_HOME`directory setup is emulated, however with exceptions for convenience.

## installation
After running a setup script in `dotfiles/scripts/setup/...` I just need to install my dotfiles & my themes.
- To deploy my dotfiles I use [pstow](https://github.com/gerelef/pstow); check the command below.
- To install my themes I use `update-ff-theme`, which is a utility located under `scripts/utils/`
- To install my compatibility layers for gaming, I use `update-compat-layers`, which is a utility located under `scripts/utils/`

**Warning! This is a DESTRUCTIVE command, and it WILL overwrite files!**

To automatically deploy the default profile:
```bash
cd ~ && git clone https://github.com/gerelef/dotfiles && ~/dotfiles/scripts/functions/pstow --source ~/dotfiles --target ~ --profile default --force --yes
```

## spellbook
- header guards
```bash
if [[ -n "$__FN_LOADED" ]]; then
    return 0
fi
readonly __FN_LOADED="__LOADED"
```
- if `__name__ == '__main__'` python equivalent
```bash
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run-my_function "$@"
```
- if there are no arguments (`$*` is empty)
```bash
[[ -z "$*" ]] && return 2
```
- if the number of arguments != 2
```bash
[[ "$#" -ne 2 ]] && return 2
```
- loop over arguments w/ array, and increment `count` by once each time
```bash
local inputs=()
local count=0
for arg in "$@"; do
    local inputs+=( -i "$arg" )
    ((++count))
done
```
- check if external/system dependency does NOT exist
```bash
if [[ -z "$(command -v ls)" ]]; then
    # do stuff
    exit 1
fi
```
- redirect find output to bash array
```bash
readarray -d '' array < <(find . -name "$input" -print0)
```
- notifications using `notify-send`
```bash
notify-send --transient --action "idiot" --action "moron" --action "doofus" Test 'hello world!'
```

## history
Large revisions were performed in the following commits, ordered by recency:
- `6231460` -> removed `./scripts/setup` and migrated them to `./scripts/functions`; also revisioned script to be ran as user rather than indescriminate `sudo`.
- `6d1a96c` -> changed gsettings integration format, effectively deprecating nobara-36 and upwards installation scripts
