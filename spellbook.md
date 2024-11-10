## dotfiles-spellbook
- spotify backup playlists
```bash
foreach spotify-dump-playlist < $(spotify-dump-public-playlist-uris-from-profile 'YOUR_PROFILE_URI_HERE')```
- initramfs blew up, regenerate:
```bash
sudo dracut --force --regenerate-all --verbose && sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
- notifications using `notify-send`
```bash
notify-send --transient --action "idiot" --action "moron" --action "doofus" Test 'hello world!'
```
