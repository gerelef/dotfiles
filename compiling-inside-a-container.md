## Compiling inside a pod

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
