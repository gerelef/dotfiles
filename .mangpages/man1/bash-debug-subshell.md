bash-debug-subshell(1) -- debug bash script in a subshell 
===========================================================

## SYNOPSIS
Debug bash script in a subshell, with `set -euxo pipefail;` enabled.

## RETURN VALUES
`exit 0` on success. Anything if the script ends abruptly.

## SYNTAX
`bash-debug-subshell <script.sh> [<'command1; ...; commandN;'>]`

## AUTHOR
[github](github.com/gerelef/)

## SECURITY CONSIDERATIONS
I try to keep up to the latest security practices, however I do not hold these practices religiously, nor should you. Some configuration files take security more seriously than others, and some do not take it into consideration at all. 
