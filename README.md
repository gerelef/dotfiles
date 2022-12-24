# dotfiles
My personal dotfiles. I do not recommend to anyone seeking inspiration to blindly copy-paste my configs; they WILL introduce problems for you. The contents of each rc file, especially the .bashrc file, have been sourced by a variety of sources, including my personal experience & particularly my preferences.

There is no particular philosophy to these configuration files, it's all personal taste, and adhere to the latest versions of applications I use between my different personal computing platforms, which are, for the most part, running the same version.

## Details:

- `rc/` contain generic configuration files from all kinds of sources. The filenames should be a hint to their usage. `.bashrc` is heavily inspired & modified by this [.bashrc](https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c). `rc/utils/` contains specific utilities that are somewhat independent; the dependencies of each script are clearly declared on the top, where they're sourced. Any function that's exported has a relevant manpage, although the code should be commented and/or is clear enough to stand on it's own. If you think otherwise for a specific function, open an issue and we can talk about it.
- `firefox/` contains firefox specific configuration files & themes. [mono-firefox-theme](https://github.com/witalihirsch/Mono-firefox-theme) is an external dependency & as such is not included in this repository. It should be automatically installed by the appropriate distribution setup script.
- `distro_setup/` contains distribution setup scripts that I created for personal use to minimize downtime, when refreshing an install of a particular distribution. They are, of course, not guaranteed to work with any hardware other than the ones I ran them with, but even then, it's a liability to assume so. If you want to see what each script does, make sure to run it in a VM, to make sure nothing's broken either by the years passing by or by bugs.
- `csgorc/` contains csgo specific configuration files, located in another github submodule. This is not something I use in each & every machine, so I thought it better not be inside the "root" `dotfile` directory.

## Extra:

### Firefox:
`user.js` contains the recommended & default options for browsing with ff >= 50
