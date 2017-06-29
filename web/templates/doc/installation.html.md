# Installation

There are several ways to get asciinema recorder:

- [Installing via Pip](#installing-via-pip)
- [Installing on Linux](#installing-on-linux)
- [Installing on Linux as snap](#installing-on-linux-as-snap) (universal Linux package)
- [Installing on macOS](#installing-on-macos)
- [Installing on FreeBSD](#installing-on-freebsd)
- [Installing on OpenBSD](#installing-on-openbsd)
- [Running in Docker container](#running-in-docker-container)
- [Running from source](#running-from-source)

If you use other operating system and you can build a native package for it then
don't hesitate, do it and let us know. We have [Github
issue](https://github.com/asciinema/asciinema/issues/116) where we track new
releases and packaging progress.

## Installing via Pip
{: #installing-via-pip}

asciinema is available on [PyPI](https://pypi.python.org/pypi/asciinema) and can
be installed with pip (Python 3 required):

    sudo pip3 install asciinema

This is the universal installation method for all operating systems, which
always provides the latest version.

## Installing on Linux
{: #installing-on-linux}

### Arch Linux

    pacman -S asciinema

### Debian

    sudo apt-get install asciinema

### Fedora

For Fedora < 22:

    sudo yum install asciinema

For Fedora >= 22:

    sudo dnf install asciinema

### Gentoo Linux

    emerge -av asciinema

### NixOS / Nix

    nix-env -i asciinema

### openSUSE

    zypper in asciinema

### Ubuntu

    sudo apt-add-repository ppa:zanchey/asciinema
    sudo apt-get update
    sudo apt-get install asciinema

## Installing on Linux as snap
{: #installing-on-linux-as-snap}

Install asciinema in seconds on [Ubuntu and other snap supported Linux distributions](https://snapcraft.io/docs/core/install) with:

    snap install asciinema --classic

Installing a snap is very quick. Snaps contain all necessary dependencies required to run. The snap will get automatically updated when a new version is pushed to the store.

## Installing on macOS
{: #installing-on-macos}

### Homebrew

    brew install asciinema

### MacPorts

    sudo port selfupdate && sudo port install asciinema

### Nix

    nix-env -i asciinema

## Installing on FreeBSD
{: #installing-on-freebsd}

### Ports

    cd /usr/ports/textproc/asciinema && make install

### Packages

    pkg install asciinema

## Installing on OpenBSD
{: #installing-on-openbsd}

    pkg_add asciinema

## Running in Docker container
{: #running-in-docker-container}

asciinema Docker image is based on Ubuntu 16.04 and has the latest version of
asciinema recorder pre-installed.

    docker pull asciinema/asciinema

When running it don't forget to allocate a pseudo-TTY (`-t`), keep STDIN open
(`-i`) and mount config directory volume (`-v`):

    docker run --rm -ti -w /asciinema -v "$(pwd -P):/asciinema" -v "$HOME/.config/asciinema":/root/.config/asciinema asciinema/asciinema

## Running from source
{: #running-from-source}

If none of the above works for you (or you want to help with development) just
clone the repo and run latest version of asciinema straight from the master
branch:

    git clone https://github.com/asciinema/asciinema.git
    cd asciinema
    python3 -m asciinema --version
