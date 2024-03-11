# dotfiles
My personal dotfiles. I do not recommend to anyone seeking inspiration to blindly copy-paste my configs; they WILL introduce problems for you. The contents of each rc file, especially the .bashrc file, have been sourced by a variety of sources, including my personal experience & particularly my preferences.
There is no particular philosophy to these configuration files, it's all personal taste, and adhere to the latest versions of applications I use between platforms, which are, for the most part, running the same OS.
The common `$XDG_CONFIG_HOME` directory setup is semi-emulated, with exceptions for convenience.

## details
- `.shell-requirements` is a requirements-style file for dependencies that are required for these dotfiles to work correctly. The appropriate handling should be done by `require-login-shell-packages` when a shell first runs.
- `.stowconfig` is a configuration file for the `pstow.py` utility under `./scripts/utils/`. The file format should be self-explanatory, however documentation should exist somewhere.
- `scripts/` contain scripts as well as some configuration files. The filenames should be a hint to their usage. 
- `.config` contains generic configuration files. The most common `$XDG_CONFIG_HOME`directory setup is emulated, however with exceptions for convenience.
- `.manpages/` contains manual pages, authored in `Markdown`, converted to manpages through `ronn`.

## submodules
- `games/cs2/` contains [CS:GO](https://store.steampowered.com/app/730/CounterStrike_Global_Offensive/) specific configuration files, located in another github submodule. This is not something I use in each & every machine, so I thought it'd better not be inside the "root" `dotfile` directory.
- `games/insurgency` contains [Insurgency](https://store.steampowered.com/app/222880/Insurgency/) specific configuration files, located in another github submodule. This is not something I use in each & every machine, so I thought it better not be inside the "root" `dotfile` directory.

## installation
The complete setup of my system assume that any `~/dotfiles/scripts/setup/...` script
has run to create the most basic of prerequisites & sane options for my usecase.
Afterwards, I just need to install my dotfiles & my themes.
- To install my dotfiles I use [pstow](https://github.com/gerelef/pstow).
- To install my themes I use `update-ff-theme`, which is a utility located under `scripts/utils/`
- To install my compatibility layers for gaming, I use `update-compat-layers`, which is a utility located under `scripts/utils/`

### run
**Warning! This is a DESTRUCTIVE command, and it WILL overwrite files!**

To automatically install the appropriate files:
```bash
cd ~ && git clone https://github.com/gerelef/dotfiles && ~/dotfiles/scripts/functions/pstow --source ~/dotfiles --target ~ --force --overwrite-others
```
