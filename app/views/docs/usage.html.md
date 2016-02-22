<% content_for(:title, 'Usage') %>

# Usage

asciinema is composed of multiple commands, similar to `git`, `apt-get` or
`brew`.

When you run `asciinema` with no arguments help message is displayed, listing
all available commands with their options.

## `rec [filename]`

__Record terminal session.__

This is the single most important command in asciinema, since it is how you
utilize this tool's main job.

By running `asciinema rec [filename]` you start a new recording session. The
command (process) that is recorded can be specified with `-c` option (see
below), and defaults to `$SHELL` which is what you want in most cases.

Recording finishes when you exit the shell (hit <kbd>Ctrl+D</kbd> or type
`exit`). If the recorded process is not a shell then recording finishes when
the process exits.

If the `filename` argument is given then the resulting recording (called
[asciicast](https://github.com/asciinema/asciinema/blob/master/doc/asciicast-v1.md))
is saved to a local file. It can later be replayed with `asciinema play
<filename>` and/or uploaded to asciinema.org with `asciinema upload
<filename>`. If the `filename` argument is omitted then (after asking for
confirmation) the resulting asciicast is uploaded to asciinema.org for further
playback in a web browser.

`ASCIINEMA_REC=1` is added to recorded process environment variables. This
can be used by your shell's config file (`.bashrc`, `.zshrc`) to alter the
prompt or play a sound when shell is being recorded.

Available options:

* `-c, --command=<command>` - Specify command to record, defaults to $SHELL
* `-t, --title=<title>` - Specify the title of the asciicast
* `-w, --max-wait=<sec>` - Reduce recorded terminal inactivity to max <sec> seconds
* `-y, --yes` - Answer "yes" to all prompts (e.g. upload confirmation)
* `-q, --quiet` - Be quiet, suppress all notices/warnings (implies -y)

## `play <filename>`

__Replay recorded asciicast in a terminal.__

This command replays given asciicast (as recorded by `rec` command) directly in
your terminal.

Playing from a local file:

    asciinema play /path/to/asciicast.json

Playing from HTTP(S) URL:

    asciinema play https://asciinema.org/a/22124.json
    asciinema play http://example.com/demo.json

Playing from asciicast page URL (requires `<link rel="alternate"
type="application/asciicast+json" href="....json">` in page's HTML):

    asciinema play https://asciinema.org/a/22124
    asciinema play http://example.com/blog/post.html

Playing from stdin:

    cat /path/to/asciicast.json | asciinema play -
    ssh user@host cat asciicast.json | asciinema play -

Playing from IPFS:

    asciinema play ipfs:/ipfs/QmcdXYJp6e4zNuimuGeWPwNMHQdxuqWmKx7NhZofQ1nw2V
    asciinema play fs:/ipfs/QmcdXYJp6e4zNuimuGeWPwNMHQdxuqWmKx7NhZofQ1nw2V

Available options:

* `-w, --max-wait=<sec>` - Reduce replayed terminal inactivity to max <sec> seconds

NOTE: it is recommended to run `asciinema play` in a terminal of dimensions not
smaller than the one used for recording as there's no "transcoding" of control
sequences for new terminal size.

## `upload <filename>`

__Upload recorded asciicast to asciinema.org site.__

This command uploads given asciicast (as recorded by `rec` command) to
asciinema.org for further playback in a web browser.

`asciinema rec demo.json` + `asciinema play demo.json` + `asciinema upload
demo.json` is a nice combo for when you want to review an asciicast before
publishing it on asciinema.org.

## `auth`

__Assign local recorder token to asciinema.org account.__

On every machine you install asciinema recorder, you get a new, unique API
token. This command connects this local token with your asciinema.org account,
and links all asciicasts recorded on this machine with the account.

This command displays the URL you should open in your web browser. If you never
logged in to asciinema.org then your account will be created when opening the
URL.

NOTE: it is __necessary__ to do this if you want to __edit or delete__ your
recordings on asciinema.org.

You can synchronize your [config file](<%= docs_path(:config) %>) (which keeps
the API token) across the machines but that's not necessary. You can assign new
tokens to your account from as many machines as you want.
