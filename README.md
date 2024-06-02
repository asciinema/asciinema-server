# asciinema server

__asciinema server__ is a server-side component of the asciinema ecosystem.

It implements a hosting platform for terminal session recordings. This includes
an API endpoint for uploading recordings, which is used by the [asciinema
CLI](https://docs.asciinema.org/manual/cli/), and offers a familiar web
interface for viewing, browsing, sharing and managing recordings.

The server is built with [Elixir language](https://elixir-lang.org/) and
[Phoenix framework](https://www.phoenixframework.org/), and embeds asciinema's
virtual terminal, [avt](https://github.com/asciinema/avt), to perform tasks such
as preview generation and recording analysis.

[asciinema.org](https://asciinema.org) is a public asciinema server instance
managed by the asciinema team, offering free hosting for terminal recordings,
available to everyone. Check [asciinema.org/about](https://asciinema.org/about)
to learn more about this instance.

You can easily [self-host asciinema
server](https://docs.asciinema.org/manual/server/self-hosting/) and use the
[asciinema CLI](https://docs.asciinema.org/manual/cli/) with your own instance.
If you're not comfortable with uploading your terminal sessions to
asciinema.org, if your company policy prevents you from doing so, or if you
simply prefer self-hosting everything, then asciinema has you covered.

Notable features:

- hosting of terminal session recordings in
  [asciicast](https://docs.asciinema.org/manual/asciicast/v2/) format,
- perfectly integrated [asciinema
  player](https://docs.asciinema.org/manual/player/) for best viewing experience,
- easy [sharing](https://docs.asciinema.org/manual/server/sharing/) of
  recordings via secret links,
- easy [embedding](https://docs.asciinema.org/manual/server/embedding/) of the
  player, or linking via preview images (SVG),
- privacy friendly - no tracking, no ads,
- visibility control for recordings: unlisted (secret) or public,
- editable recording metadata like title or long description (Markdown),
- configurable terminal themes and font families,
- ability to download plain text version (`.txt`) of a recording.

Refer to [asciinema server docs](https://docs.asciinema.org/manual/server/) for
further details.

## Donations

Sustainability of asciinema development relies on donations and sponsorships.

Please help the software project you use and love. Become a
[supporter](https://docs.asciinema.org/donations/#individuals) or a [corporate
sponsor](https://docs.asciinema.org/donations/#corporate-sponsorship).

asciinema is sponsored by:

- [Brightbox](https://www.brightbox.com/)
- [DataDog](https://datadoghq.com/)

## Consulting

If you're interested in hosting, maintenance or customization of asciinema
server, check [asciinema consulting
services](https://docs.asciinema.org/consulting/).

## Copyright

© 2011 Marcin Kulik.

All code is licensed under the Apache License, Version 2.0. See LICENSE file for
details.
