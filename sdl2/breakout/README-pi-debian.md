# Raspberry Pi/Debian/aarch64

"You just need to build vcpkg from source, and install zig from snap"
- not really, vcpkg SDL mixer isn't built with the correct flags, so audio doesn't work

NOTE: sprite transparency is broken on this platform


SDL dependencies (needs to be verified again)

```sh
sudo apt install libx11-dev libxft-dev libxext-dev
sudo apt install libwayland-dev libxkbcommon-dev libegl1-mesa-dev
sudo apt install libibus-1.0-dev
sudo apt-get install libasound2-dev libpulse-dev libaudio-dev libsndio-dev libsamplerate0-dev
sudo apt-get install libvorbis-dev

sudo apt-get install libsdl2-dev
sudo apt --fix-broken install
sudo apt-get install libsdl2-mixer-dev
sudo apt-get install libsdl2-ttf-dev
```

should now work

```sh
zig build run
```

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
