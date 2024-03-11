# scripts
A directory for somewhat independent utilities. 
Most should be "executables" or executable configurations.
Source with caution.

## details
- `functions/` contains independent utilities. This directory should be appended to `$PATH` and the utilities should be called from there. **Do not source these scripts.** The code itself should be self-documenting and clear enough to stand on it's own. If you think otherwise for a specific function, open an issue and we can talk about it.
- `utils/` contains utility scripts, meant to automate common tasks. Wrappers for these scripts should exist in `$PATH`, provided in `functions/`.
- `setup/` contains distribution setup scripts that I created for personal use to minimize downtime, to automate deployment of a particular distribution. They are not guaranteed to work with any hardware other than the ones I ran them with, but even then it's a liability to assume so. If you want to see what each script does, make sure to run it in a VM, to make sure nothing's broken either by the years passing by or by bugs.
- `.bashrc` was originally inspired & started by this [.bashrc](https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c).
- `.nanorc` is an amalgamation of many copy-pastes; has basic highlighting for some things, and a few options to make the experience worthwhile.
- `.gitconfig` is my personal flavour of [git](https://git-scm.com/) aliases.
