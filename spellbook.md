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
- read from stdin
```bash
str=$(cat -)
```
- heredocs
```bash
cat << EOF
Today's date is $TODAY
Current user is $(whoami)
EOF
```
- multiline comments with heredocs
```bash
<< COMMENT
This is a comment line 1
This is another comment line
COMMENT
```
- herestrings
```bash
tr a-z A-Z <<< 'one two three'
# Output: ONE TWO THREE
```
- initramfs blew up, regenerate:
```bash
sudo dracut --force --regenerate-all --verbose && sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
- notifications using `notify-send`
```bash
notify-send --transient --action "idiot" --action "moron" --action "doofus" Test 'hello world!'
```
