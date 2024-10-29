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
- Calibrate [flatness value](https://forum.scssoft.com/viewtopic.php?t=273373)
```bash
sudo evdev-joystick --evdev /dev/input/by-id/usb-Thrustmaster_Thrustmaster_T150RS-event-joystick --d 0
```
