# asciinema web app

asciinema is a free and open source solution for recording terminal sessions
and sharing them on the web.

This repository contains the source code of asciinema hosting web app, which
runs at [asciinema.org](https://asciinema.org).

You can find the source code of asciinema terminal recorder
at [asciinema/asciinema](https://github.com/asciinema/asciinema), and the source
code of asciinema web player
at [asciinema/asciinema-player](https://github.com/asciinema/asciinema-player).

Shout-out to our Platinum [sponsors](https://github.com/sponsors/ku1ik), whose
financial support helps keep the project alive:

[<img src="./assets/static/images/sponsor-logos/dashcam/logo-on-light.png" width="200" />](https://dashcam.io?utm_source=asciinemagithub)

## Setting up your own asciinema web app instance

asciinema terminal recorder uses [asciinema.org](https://asciinema.org) as its
default host for the recordings. It's free, public service (all uploaded
recordings are __private by default__ though).

If you're not comfortable with uploading your terminal sessions to
asciinema.org, or your company's policy prevents you from doing that, you can
set up your own instance for private use. See
our [asciinema server install guide](https://github.com/asciinema/asciinema-server/wiki/Installation-guide).

Once you have your instance running, point asciinema recorder to it by setting
API URL in `~/.config/asciinema/config` file as follows:

```ini
[api]
url = https://your.asciinema.host
```

Alternatively, you can set `ASCIINEMA_API_URL` environment variable:

    ASCIINEMA_API_URL=https://your.asciinema.host asciinema rec

## Security

Security of this web app and user data it manages is important.
If you find anything that looks like a potential vulnerability please
read on
[how to report a security issue](https://github.com/asciinema/asciinema-server/blob/main/CONTRIBUTING.md#reporting-security-issues).

## Sponsors

asciinema is sponsored by:

- [Brightbox](https://www.brightbox.com/)

## Consulting

I offer consulting services for asciinema project. See https://asciinema.org/consulting for more information.

## Contributing

Check out our [Contributing](http://asciinema.org/contributing) page, which
describes multiple ways you can help this project.

If you decide to contribute with the code then please
read [CONTRIBUTING.md](https://github.com/asciinema/asciinema-server/blob/main/CONTRIBUTING.md), which covers submitting bugs,
requesting new features, preparing your code for a pull request, etc.

## Authors

asciinema is developed by [Marcin Kulik](http://ku1ik.com) with the help of
many great open source contributors.

For a complete list of the many individuals that contributed to the project,
please refer to
[GitHub's list of contributors](https://github.com/asciinema/asciinema-server/contributors).

## Copyright

© 2011 Marcin Kulik.

All code is licensed under the Apache License, Version 2.0. See LICENSE file for details.
