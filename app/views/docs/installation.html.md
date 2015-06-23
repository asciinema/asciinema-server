<% content_for(:title, 'Installation') %>

# Installation

## The easy way

<%= render partial: 'docs/script_install' %>

## Manual download

You can
[download the latest binary](https://github.com/asciinema/asciinema/releases)
for your platform and place it in your `$PATH`.

## Using package manager

You can also use your favorite package manager to install asciinema recorder.
Note that it takes time for native packages to be updated so you may not get
the latest released version.

### OS X

On OS X asciinema is available via Homebrew:

    brew update
    brew install asciinema

Or via MacPorts:

    sudo port selfupdate
    sudo port install asciinema

### Arch Linux

Arch Linux users can install the
[AUR package](https://aur.archlinux.org/packages/asciinema/):

    sudo yaourt -S asciinema

### Fedora

asciinema rpm package is included in the main Fedora 19 and 20 repository:

    sudo yum install asciinema

### Gentoo Linux

Gentoo Linux users can install asciinema from
[Mauro Toffanin's overlay](https://github.com/Dr-Terrible/go-overlay):

    emerge -av app-portage/layman
    wget -q -O /etc/layman/overlays/go-overlay.xml https://raw.github.com/Dr-Terrible/go-overlay/master/overlay.xml
    layman -Lk
    layman -a go-overlay
    emerge -av dev-go/asciinema

### Nix / NixOS

If you're using Nix package manager then we have you covered too:

    nix-env -i asciinema

### Ubuntu

To install Ubuntu package add
[zanchey ppa](https://launchpad.net/~zanchey/+archive/asciinema) to your
software sources list:

    sudo apt-add-repository ppa:zanchey/asciinema
    sudo apt-get update
    sudo apt-get install asciinema

### No package for your operating system?

If you use other operating system and you know how to build a native package
for it then don't hesitate, build one and let us know.

## From source

For instructions on building asciinema from source please refer to the
[README file](https://github.com/asciinema/asciinema/blob/master/README.md).
