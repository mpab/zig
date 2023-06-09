# Installing on Lunix variants

SDL dependencies: tested on

- Raspberry Pi/Debian bullseye normal/full (not lite)
- WSL2/Debian

```sh
sudo apt-get install -y libsdl2-dev libsdl2-ttf-dev libsdl2-mixer-dev
sudo apt-get install -y libogg-dev libvorbis-dev
# WSL2/Debian dependencies
sudo apt-get install -y automake libfreetype-dev libfreetype6 libfreetype6-dev libharfbuzz-dev
```

...then build/run as normal

~~NOTE: sprite transparency is broken on this platform - possibly due to the SDL version~~

FIXED: use default PixelFormatEnum with alpha channel

---

## Raspberry Pi/Debian/aarch64

"You just need to build vcpkg from source, and install zig from snap"

- not really, vcpkg SDL mixer isn't built with the correct flags, so audio doesn't work

---

## vcpkg notes (not working...)

```sh
# install dependencies
sudo apt update
sudo apt install snapd
sudo snap install core
sudo reboot # may not be required
sudo snap install zig --beta --classi
sudo apt-get install ninja-build
mkdir -p ~/dev
cd ~/dev

# build vcpkg
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
```

```sh
# edit ~/.bashrc
export PATH=$PATH:$HOME/dev/vcpkg
export VCPKG_FORCE_SYSTEM_BINARIES
```

error?  
e.g. CMake 3.21 or higher is required.  You are running version 3.18.4

```sh
sudo snap install cmake --classic
# edit ~/.bashrc
alias "cmake"="snap run cmake" # use the snap version of cmake
sudo mv /usr/bin/cmake /usr/bin/cmake_old # still on path...
```

...then rebuild vcpkg

## install and build from source

Not working (issues with header files)

[build-install-SDL2](./build-install-SDL2)
