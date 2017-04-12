<% content_for(:title, 'Installation') %>

# Installation

## Python package

asciinema is available on [PyPI](https://pypi.python.org/pypi/asciinema) and can
be installed with pip (Python 3 required):

    sudo pip3 install asciinema

## Docker image

asciinema Docker image is based on Ubuntu 16.04 and has the latest version of
asciinema recorder pre-installed.

    docker pull asciinema/asciinema

When running it don't forget to allocate a pseudo-TTY (`-t`), keep STDIN open
(`-i`) and mount config directory volume (`-v`):

    docker run --rm -ti -v "$HOME/.config/asciinema":/root/.config/asciinema asciinema/asciinema

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

### OpenBSD

    pkg_add asciinema

### openSUSE

    zypper in asciinema

### OS X

Homebrew:

<%= render 'install_homebrew' %>

MacPorts:

    sudo port selfupdate && sudo port install asciinema

Nix:

    nix-env -i go1.4-asciinema

### Ubuntu

    sudo apt-add-repository ppa:zanchey/asciinema
    sudo apt-get update
    sudo apt-get install asciinema

### No package for your operating system?

If you use other operating system and you can build a native package for it then
don't hesitate, do it and let us know. We have [Github
issue](https://github.com/asciinema/asciinema/issues/116) where we track new
releases and packaging progress.

## Running latest version from master

If none of the above works for you (or you want to help with development) just
clone the repo and run asciinema straight from the checkout:

    git clone https://github.com/asciinema/asciinema.git
    cd asciinema
    python3 -m asciinema --version
