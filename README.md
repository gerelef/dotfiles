# dotfiles

My personal dotfiles. I do not recommend to anyone seeking inspiration to blindly copy-paste my configs; they WILL introduce problems for you. The contents of each rc file, especially the .bashrc file, have been sourced by a variety of sources, including my personal experience & particularly my preferences.
There is no particular philosophy to these configuration files, it's all personal taste, and adhere to the latest versions of applications I use between platforms, which are, for the most part, running the same OS.
The common `$XDG_CONFIG_HOME` directory setup is semi-emulated, with exceptions for convenience.

## details

- `.shell-requirements` is a requirements-style file for dependencies that are required for these dotfiles to work correctly.
- `.stowconfig` is a configuration file for the `pstow.py` utility under `./scripts/utils/`. The file format should be self-explanatory, however documentation should exist somewhere.
- `scripts/` contain scripts as well as some configuration files. The filenames should be a hint to their usage.
- `.config` contains generic configuration files. The most common `$XDG_CONFIG_HOME`directory setup is emulated, however with exceptions for convenience.

## installation

After running a setup script in `dotfiles/scripts/setup/...` I just need to install my dotfiles & my themes.

- To deploy my dotfiles I use [pstow](https://github.com/gerelef/pstow); check the command below.
- To install my compatibility layers for gaming, I use `update-compat-layers`, which is a utility located under `scripts/utils/`
- To set CTRL+Tab / CTRL+Shift+Tab as a shortcut in chrome, I use the following snippet from [superuser](https://superuser.com/questions/104917/chrome-tab-ordering/1326712#1326712)

```js
document.body.onclick = function (e) {
    gCT = !window.gCT;
    const p = e.composedPath(),
        cn = p[0].textContent,
        s = p.filter((p) => p.className == "shortcut-card")[0],
        n = s?.children[0].children[1].textContent;
    if (n)
        chrome.management.getAll((es) => {
            const ext = es.filter((e) => e.name == n)[0],
                { id } = ext;
            chrome.developerPrivate.getExtensionInfo(id, (i) => {
                const c = i.commands.filter((c) => c.description == cn)[0];
                if (c)
                    chrome.developerPrivate.updateExtensionCommand({
                        extensionId: id,
                        commandName: c.name,
                        keybinding: `Ctrl+${gCT ? "" : "Shift+"}Tab`,
                    });
            });
        });
};
```

To automatically deploy the default profile:
**Warning! This is a DESTRUCTIVE command, and it WILL overwrite files!**

```bash
cd ~ && git clone https://github.com/gerelef/dotfiles && ~/dotfiles/scripts/functionz/pstow --source ~/dotfiles --target ~ --profile default --force --yes
```

## spellbook

- spotify backup playlists

````bash
foreach spotify-dump-playlist < $(spotify-dump-public-playlist-uris-from-profile 'YOUR_PROFILE_URI_HERE')```
- initramfs blew up, regenerate:
```bash
sudo dracut --force --regenerate-all --verbose && sudo grub2-mkconfig -o /boot/grub2/grub.cfg
````

- notifications using `notify-send`

```bash
notify-send --transient --action "idiot" --action "moron" --action "doofus" Test 'hello world!'
```

- string (.) split('|') equivalent

```bash
IFS='|' read -r var1 var2 var3 <<< $(echo $line)
```

- view stacktrace of what a command is actually doing

```bash
strace -s 2000 -o unlink.log unlink file1
```

## services

Additionally to the services in the `scripts/functionz/units/*`, I also sometimes host the following services:

- ollama
- open-webui

**IMPORTANT:** You should **copy** the service files to the appropriate directory as specified below

system services:

```bash
# make sure you replace $1 with the file name
sudo cp ./$1 "/etc/systemd/system/" && sudo chown root:root "/etc/systemd/system/$1"
```

user services:

```bash
# make sure you replace $1 with the file name
#  you can also softlink or hardlink this, but for consistency purposes it is
#  not recommended.
cp ./$1 "~/.config/systemd/user/"
```

## thrustmaster t150 setup

The current steps provided will NOT work with secure boot.

- Drivers (requires `dkms` pkg), courtesy of scarburato:
  https://github.com/scarburato/t150_driver
- Oversteer:
  https://github.com/berarma/oversteer

```bash
sudo dnf install python3 python3-distutils-extra python3-gobject \
python3-pyudev python3-pyxdg python3-evdev \
gettext meson appstream desktop-file-utils python3-matplotlib-gtk3 \
python3-scipy
git clone https://github.com/berarma/oversteer && cd oversteer
meson setup build
cd ./build/
sudo ninja install
sudo udevadm control --reload-rules && sudo udevadm trigger
```

- Calibrate [flatness value](https://forum.scssoft.com/viewtopic.php?t=273373); will NOT persist!

```bash
sudo evdev-joystick --evdev /dev/input/by-id/usb-Thrustmaster_Thrustmaster_T150RS-event-joystick --d 0
```

## compiling inside a pod

```bash
# create pod with passt (pasta) for network
# a debian-based LTS distro is prefered, for stable & reproducible environments
podman run --replace --name compiler-container --network pasta -it ubuntu:20.04 /bin/bash
# some of these packages should exist everywhere
apt update && apt install -y libglib2.0-dev \
    build-essential git meson ninja-build \
    gcc pkg-config libudev-dev libevdev-dev \
    libjson-glib-dev libunistring-dev libsystemd-dev \
    check python3-dev valgrind swig
git clone https://github.com/libratbag/libratbag.git && cd libratbag
meson builddir && ninja -C builddir
ninja -C builddir install
exit
```

... after exiting, to copy a specific directory:

```bash
# ... get the container id via `podman ps --all`
podman cp 2781d27699f5:/libratbag ./libratbag
podman stop 2781d27699f5  # probably unnecessary, but for good measure
podman rm 2781d27699f5  # delete it!
```
