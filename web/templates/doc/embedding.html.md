# Sharing & embedding

You can share any recording by copying its URL and sending it to a friend or
posting it on a social network. asciinema.org supports oEmbed/Open Graph/Twitter
Card protocols, displaying a nice thumbnail where possible.

You can also easily embedded an asciicast on any HTML page. If you want to put a
recording in a blog post, project's documentation or in a conference talk
slides, you can do it by copy-pasting one of the the embed scripts.

## Sharing a link

You can get the share link for a specific asciicast by clicking on "Share" link
on asciicast page.

Any of the options listed in "Customizing the playback" section below can be
appended to the asciicast URL as the query params, e.g.:

    https://asciinema.org/a/14?t=25&speed=2&theme=solarized-dark

Visiting this link will start the playback at 25s and play at double speed,
using Solarized Dark terminal theme.

## Embedding image link

Embedding as an image link is useful in places where scripts are not allowed,
e.g. in a project's README file.

You can get the embed snippets for a specific asciicast by clicking on "Share"
link on asciicast page.

This is how they look for asciicast 14:

HTML:

    <a href="https://asciinema.org/a/14"><img src="https://asciinema.org/a/14.png" width="836"/></a>

Markdown:

    [![asciicast](https://asciinema.org/a/14.png)](https://asciinema.org/a/14)

You can pass extra options (listed in "Customizing the playback" below) to the
linked URL as query params. For example, to start the playback automatically
when opening linked asciicast page append `?autoplay=1` to the asciicast URL in
`href` attribute:

    <a href="https://asciinema.org/a/14?autoplay=1"><img src="https://asciinema.org/a/14.png" width="836"/></a>

## Embedding the player

If you're embedding on your own page or on a site which permits script tags, you
can use the full player widget.

You can get the widget script for a specific asciicast by clicking on "Embed"
link on asciicast page.

It looks like this:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async></script>

The player shows up right at the place where the script is pasted. Let's look
at the following markup:

    <p>This is some text.</p>
    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async></script>
    <p>This is some other text.</p>

The player is displayed between the two paragraphs, as a `div` element with
"asciicast" class.

The embed script supports all customization options (see the section below). An
option can be specified by adding it as a
<code>data-<em>option-name</em>="<em>value</em>"</code> attribute to the script
tag.

For example, to make the embedded player auto start playback when loaded and use
big font, use the following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-autoplay="true" data-size="big"></script>

## Customizing the playback

The player supports several options that control the behavior and look of it.
Append them to the URL (`?speed=2&theme=tango`) or set them as data attributes
on embed script (`data-speed="2" data-theme="tango"`).

### t

The `t` option specifies the time at which the playback should start. The
default is `t=0` (play from the beginning).

Accepted formats: `ss`, `mm:ss`, `hh:mm:ss`.

NOTE: when `t` is specified then `autoplay=1` is implied. To prevent the player
from starting automatically when `t` option is set you have to explicitly set
`autoplay=0`.

### autoplay

The `autoplay` option controls whether the playback should automatically start
when the player loads. Accepted values:

* 0 / false - do not start playback automatically (default)
* 1 / true - start playback automatically

### preload

The `preload` option controls whether the player should immediately start
fetching the recording.

* 0 / false - do not preload the recording, wait for user action
* 1 / true - preload the recording

Defaults to 1 for asciinema.org URLs, to 0 for embed script.

### loop

The `loop` option allows for looping the playback. This option is usually
combined with `autoplay` option. Accepted values:

* 0 / false - disable looping (default)
* 1 / true - enable looping

### speed

The `speed` option alters the playback speed. The default speed is 1 which
means it plays at the unaltered, original speed.

### size

The `size` option alters the size of the terminal font. There are 3 available
sizes:

* small (default)
* medium
* big

### theme

The `theme` option allows overriding a theme used for the terminal. It defaults
to a theme set by the asciicast author (or to "asciinema" if not set by the
author). The available themes are:

* asciinema
* tango
* solarized-dark
* solarized-light
* monokai

## oEmbed / Open Graph / Twitter Card

asciinema supports [oEmbed](http://oembed.com/), [Open Graph](http://ogp.me/)
and [Twitter Card](https://dev.twitter.com/cards/overview) APIs. When you share
an asciicast on Twitter, Slack, Facebook, Google+ or any other site which
supports one of these APIs, the asciicast is presented in a rich form (usually
with a title, author, description and a thumbnail image), linking to your
recording on asciinema.org.
