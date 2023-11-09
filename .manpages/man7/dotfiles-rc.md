dotfiles-rc(7) -- configuration files for various applications 
===========================================================

## SYNOPSIS
Generic configuration files from all kinds of sources. The filenames should be a hint to their usage. `.bashrc` is heavily inspired & modified by this [.bashrc](https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c). `rc/utils/` contains specific utilities that are somewhat independent; the dependencies of each script are clearly declared on the top, where they're sourced. Any function that's exported should have a relevant manpage, although the code should be commented and/or is clear enough to stand on it's own. If you think otherwise for a specific function, open an issue and we can talk about it.

## AUTHOR
[github](github.com/gerelef/)

## SECURITY CONSIDERATIONS
I try to keep up to the latest security practices, however I do not hold these practices religiously, nor should you. Some configuration files take security more seriously than others, and some do not take it into consideration at all. 

## SEE ALSO
dotfiles-csgorc(7), dotfiles-firefox(7), dotfiles(7), dotfiles-man(7)
