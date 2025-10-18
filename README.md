# asciinema server

__asciinema server__ is a server-side component of the asciinema ecosystem.

It implements a hosting platform for terminal session recordings and live
streaming. It offers a familiar web interface for viewing, browsing, sharing
and managing recordings and streams. This includes [HTTP
API](https://docs.asciinema.org/manual/server/api.md), which is used by the
[asciinema CLI](https://docs.asciinema.org/manual/cli/index.md).

The server is built with [Elixir language](https://elixir-lang.org/) and
[Phoenix framework](https://www.phoenixframework.org/). It embeds asciinema's
virtual terminal, [avt](https://github.com/asciinema/avt), which is utilized by
tasks such as preview generation, recording analysis and live stream state
bookkeeping.

[asciinema.org](https://asciinema.org) is a public asciinema server instance
managed by the asciinema project team, providing free hosting for terminal
recordings and streams, available to everyone. Check
[asciinema.org/about](https://asciinema.org/about) to learn more about this
instance.

You can easily [self-host asciinema
server](https://docs.asciinema.org/manual/server/self-hosting) and use
the [asciinema CLI](https://docs.asciinema.org/manual/cli) with your
own instance. If you're not comfortable with hosting your data at
asciinema.org, if your company policy prevents you from doing so, or if you
simply prefer self-hosting everything, then asciinema has you covered.

Notable features:

- hosting of terminal session recordings in
  [asciicast](https://docs.asciinema.org/manual/asciicast/v3/) format,
- [live streaming](https://docs.asciinema.org/manual/server/streaming/) of
  terminal sessions,
- perfectly integrated [asciinema
  player](https://docs.asciinema.org/manual/player/) for best viewing experience,
- easy [sharing](https://docs.asciinema.org/manual/server/sharing/) of
  recordings via secret links,
- easy [embedding](https://docs.asciinema.org/manual/server/embedding/) of the
  player, or linking via preview images (SVG),
- privacy friendly - no tracking, no ads,
- visibility control for recordings and streams: private, unlisted, or public,
- editable recording/stream metadata like title or long description (Markdown),
- configurable terminal themes and font families,
- download of plain text transcripts (`.txt`) of a recordings.

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
