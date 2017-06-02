# asciinema web app

[![Build Status](https://travis-ci.org/asciinema/asciinema.org.svg?branch=master)](https://travis-ci.org/asciinema/asciinema.org)
[![Code Climate](https://codeclimate.com/github/asciinema/asciinema.org/badges/gpa.svg)](https://codeclimate.com/github/asciinema/asciinema.org)
[![Coverage Status](https://coveralls.io/repos/asciinema/asciinema.org/badge.svg)](https://coveralls.io/r/asciinema/asciinema.org)

asciinema is a free and open source solution for recording terminal sessions
and sharing them on the web.

This repository contains the source code of asciinema hosting web app, which
runs at [asciinema.org](https://asciinema.org).

You can find the source code of asciinema terminal recorder
at [asciinema/asciinema](https://github.com/asciinema/asciinema), and the source
code of asciinema web player
at [asciinema/asciinema-player](https://github.com/asciinema/asciinema-player).

## Setting up your own asciinema web app instance

asciinema terminal recorder uses [asciinema.org](https://asciinema.org) as its
default host for the recordings. It's free, public service (all uploaded
recordings are __private by default__ though).

If you're not comfortable with uploading your terminal sessions to
asciinema.org, or your company's policy prevents you from doing that, you can
set up your own instance for private use. See
our [asciinema web app install guide](docs/INSTALL.md).

Once you have your instance running, point asciinema recorder to it by setting
API URL in `~/.config/asciinema/config` file as follows:

    [api]
    url = https://your.asciinema.host

Alternatively, you can set `ASCIINEMA_API_URL` environment variable:

    ASCIINEMA_API_URL=https://your.asciinema.host asciinema rec

## Contributing

Check out our [Contributing](http://asciinema.org/contributing) page, which
describes multiple ways you can help this project.

If you decide to contribute with the code then please
read [CONTRIBUTING.md](CONTRIBUTING.md), which covers submitting bugs,
requesting new features, preparing your code for a pull request, etc.

## Security

We're serious about the security of this web app and the user data it manages.
If you find anything that looks like a potential vulnerability please
read on
[how to report a security issue](CONTRIBUTING.md#reporting-security-issues).

## Authors

asciinema is developed by [Marcin Kulik](http://ku1ik.com) with the help of
many great open source contributors.

For a complete list of the many individuals that contributed to the project,
please refer to
[GitHub's list of contributors](https://github.com/asciinema/asciinema.org/contributors).

## Copyright

Copyright &copy; 2011-2017 Marcin Kulik. See LICENSE for details.
