# dotfiles
My personal dotfiles. I do not recommend to anyone seeking inspiration to blindly copy-paste my configs; they WILL introduce problems for you. The contents of each rc file, especially the .bashrc file, have been sourced by a variety of sources, including my personal experience & particularly my preferences.

There is no particular philosophy to these configuration files, it's all personal taste, and adhere to the latest versions of applications I use between my different personal computing platforms, which are, for the most part, running the same version.

## Details:

- `rc/` directory contain generic configuration files from all kinds of sources. The filenames should be a hint for their usage.
- `firefox/` contains firefox specific configuration files & themes. 
- `distro_setup/` contains distribution setup scripts that I created for personal use to minimize downtime, when refreshing an install of a particular distribution. They are, of course, not guaranteed to work with any hardware other than the ones I ran them with, but even then, it's a liability to assume so. If you want to see what each script does, make sure to run it in a VM, to make sure nothing's broken either by the years passing by or by bugs.
- `csgorc/` contains csgo specific configuration files, located in another github submodule. This is not something I use in each & every machine, so I thought it better not be inside the "root" `dotfile` directory.

## Extra:

### Firefox:
`user.js` contains the recommended & default options for browsing with ff >= 50
