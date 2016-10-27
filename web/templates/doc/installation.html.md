# Installation

## Python package

asciinema is available on [PyPI](https://pypi.python.org/pypi/asciinema) and can
be installed with pip (Python 3 required):

    sudo pip3 install asciinema

## Native packages

### Arch Linux

    pacman -S asciinema

### Debian

    sudo apt-get install asciinema

### Fedora

For Fedora < 22:

    sudo yum install asciinema

For Fedora >= 22:

    sudo dnf install asciinema

### FreeBSD

Ports:

    cd /usr/ports/textproc/asciinema && make install

Packages:

    pkg install asciinema

### Gentoo Linux

    emerge -av asciinema

### NixOS / Nix

    nix-env -i go1.4-asciinema

### OS X

Homebrew:

    brew update && brew install asciinema

MacPorts:

    sudo port selfupdate && sudo port install asciinema

Nix:

    nix-env -i go1.4-asciinema

### Ubuntu

    sudo apt-add-repository ppa:zanchey/asciinema
    sudo apt-get update
    sudo apt-get install asciinema

### No package for your operating system?

If you use other operating system and you can build a native package
for it then don't hesitate, do it and let us know.

## Running latest version from master

If none of the above works for you (or you want to help with development) just
clone the repo and run asciinema straight from the checkout:

    git clone https://github.com/asciinema/asciinema.git
    cd asciinema
    python3 -m asciinema --version
