## .manpages
Manual pages, authored in `Markdown`, converted to manpages through `ronn`. 

## details
Set like this in your `.bashrc`:
```sh
export MANPATH="$MANPATH:$DOTFILES_DIR/man"
```
Where `$DOTFILES_DIR` is a bash variable pointing to the root dotfile directory.
Manpages are generated using `ronn-format` provided by the `rubygem-ronn-ng` under `Fedora 36`.
Further reading:
- [man ronn](https://rtomayko.github.io/ronn/ronn.1.html)
- [man ronn-format](https://rtomayko.github.io/ronn/ronn-format.7.html)

## categories
Categories are as follows (as per this [manual](https://tldp.org/HOWTO/Man-Page/q2.html)):
1) User commands that may be started by everyone.[^1]
2) System calls, that is, functions provided by the kernel.
3) Subroutines, that is, library functions.
4) Devices, that is, special files in the /dev directory.
5) File format descriptions, e.g. /etc/passwd.
6) Games, self-explanatory.
7) Miscellaneous, e.g. macro packages, conventions.[^2]
8) System administration tools that only root can execute.
9) Another (Linux specific) place for kernel routine documentation.

[^1]: In this case, `man1` explains all **exported functions** provided by any bash file. 
[^2]: In this case, `man7` explains the dotfile directory structure.
