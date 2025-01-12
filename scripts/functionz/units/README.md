## services
Additionally to the services in the `$CWD`, I also host the following services:
- ollama
- open-webui

### Important note:
You should **copy** the service files to the appropriate directory.

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
