<% content_for(:title, 'Embedding') %>

# Embedding

An asciicast can be easily embedded on any HTML page. If you want to put a
recording in a blog post, project's documentation or in a conference talk
slides, you can do it by copy-pasting one of the the embed scripts. In
addition, you can share it on your favorite social network thanks to
oEmbed/Open Graph/Twitter Card support.

## Image link

Embedding as an image link is useful in places where scripts are not allowed,
e.g. in a project's README file.

You can get the embed snippets for a specific asciicast by clicking on "Embed"
link on asciicast page.

See the example below for asciicast 14.

HTML:

    <a href="https://asciinema.org/a/14"><img src="https://asciinema.org/a/14.png" width="836"/></a>

Markdown:

    [![asciicast](https://asciinema.org/a/14.png)](https://asciinema.org/a/14)

To start the playback automatically after opening linked asciicast page append
`?autoplay=1` to asciicast URL:

    <a href="https://asciinema.org/a/14?autoplay=1"><img src="https://asciinema.org/a/14.png" width="836"/></a>

## Player

If you're embedding on your own page or on a site which permits script tags,
you can use the full player widget:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async></script>

The player shows up right at the place where the script is pasted. Let's look
at the following markup:

    <p>This is some text.</p>
    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async></script>
    <p>This is some other text.</p>

The player is displayed between the two paragraphs, as a `div` element with
"asciicast" class.

You can get the player widget script for a specific asciicast by clicking on
"Embed" link on asciicast page.

### Customizing the player

The embed script supports several customization options. An option can be
applied by adding it as a
<code>data-<em>option-name</em>="<em>option-value</em>"</code> attribute to
the script tag.

#### speed

The `speed` option alters the playback speed. The default speed is 1 which
means it plays at the unaltered, original speed.

For example, to make the playback 2 times faster than original use the
following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-speed="2"></script>

#### size

The `size` option alters the size of the terminal font. There are 3 available
sizes:

* small (default)
* medium
* big

For example, to make the font big use the following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-size="big"></script>

#### theme

The `theme` option allows overriding a theme used for the terminal.
It defaults to a theme set by the asciicast author (or to "tango" if not set
by the author).  There are 3 available themes:

* tango
* solarized-dark
* solarized-light

For example, to use Solarized Dark theme use the following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-theme="solarized-dark"></script>

#### autoplay

The `autoplay` option allows for automatic playback start when the player
loads. Accepted values:

* 0 / false - do not start playback automatically (default)
* 1 / true - start playback automatically

For example, to make the asciicast auto play use the following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-autoplay="true"></script>

#### loop

The `loop` option allows for looping the playback. This option is usually
combined with `autoplay` option. Accepted values:

* 0 / false - disable looping (default)
* 1 / true - enable looping

For example, to make the asciicast play infinitely use the following script:

    <script type="text/javascript" src="https://asciinema.org/a/14.js" id="asciicast-14" async data-loop="true"></script>

## oEmbed / Open Graph / Twitter Card

asciinema supports [oEmbed](http://oembed.com/), [Open Graph](http://ogp.me/)
and [Twitter Card](https://dev.twitter.com/cards/overview) APIs. When you share
an asciicast on Twitter, Slack, Facebook, Google+ or any other site which
supports one of these APIs, the asciicast is presented in a rich form (usually
with a title, author, description and a thumbnail image), linking to your
recording on asciinema.org.
