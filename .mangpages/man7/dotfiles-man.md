dotfiles-man(7) -- manpages 
===========================================================

## SYNOPSIS
Manual pages, authored in `Markdown`, converted to manpages through `ronn`. They describe things that I need to look once in a time, and some information outsiders might find useful as well.
Please note that these won't be as up-to-date as looking to the code/config file directly, because of time & will restraints. 

## USAGE

Set like this in your `.bashrc`:
```sh
export MANPATH="$MANPATH:$DOTFILES_DIR/man"
```
Where `$DOTFILES_DIR` is a bash variable pointing to the root dotfile directory.
Manpages are generated using `ronn-format` provided by the `rubygem-ronn-ng` under `Fedora 36`.
Further reading:
- [man ronn](https://rtomayko.github.io/ronn/ronn.1.html)
- [man ronn-format](https://rtomayko.github.io/ronn/ronn-format.7.html)

## CATEGORIES

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

## AUTHOR
[github](github.com/gerelef/)

## SECURITY CONSIDERATIONS
I try to keep up to the latest security practices, however I do not hold these practices religiously, nor should you. Some configuration files take security more seriously than others, and some do not take it into consideration at all. 

## SEE ALSO
dotfiles-csgorc(7), dotfiles-firefox(7), dotfiles(7), dotfiles-rc(7)
