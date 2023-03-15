# How it works

asciinema project is built of several complementary pieces:

* command-line based terminal session recorder, `asciinema`,
* website with an API at asciinema.org,
* javascript player

When you run `asciinema rec` in your terminal the recording starts, capturing
all output that is being printed to your terminal while you're issuing the
shell commands. When the recording finishes (by hitting <kbd>Ctrl-D</kbd> or
typing `exit`) then the captured output is uploaded to asciinema.org website
and prepared for playback on the web.

Here's a brief overview of how these parts work.

## Recording

You probably know `ssh`, `screen` or `script` command. Actually, asciinema
was inspired by `script` (and `scriptreplay`) commands. What you may not know
is they all use the same UNIX system capability: [a
pseudo-terminal](http://en.wikipedia.org/wiki/Pseudo_terminal).

> A pseudo terminal is a pair of pseudo-devices, one of which, the slave,
> emulates a real text terminal device, the other of which, the master,
> provides the means by which a terminal emulator process controls the slave.

Here's how terminal emulator interfaces with a user and a shell:

> The role of the terminal emulator process is to interact with the user; to
> feed text input to the master pseudo-device for use by the shell (which is
> connected to the slave pseudo-device) and to read text output from the
> master pseudo-device and show it to the user.

In other words, pseudo-terminals give programs the ability to act as a
middlemen between the user, the display and the shell. It allows for
transparent capture of user input (keyboard) and terminal output (display).
`screen` command utilizes it for capturing special keyboard shortcuts
like <kbd>Ctrl-A</kbd> and altering the output in order to display window
numbers/names and other messages.

asciinema recorder does its job by utilizing pseudo-terminal for capturing all
the output that goes to a terminal and saving it in memory (together with timing
information). The captured output includes all the text and invisible
escape/control sequences in a raw, unaltered form. When the recording session
finishes it uploads the output (in
[asciicast format](https://github.com/asciinema/asciinema/blob/main/doc/asciicast-v2.md))
to asciinema.org. That's all about "recording" part.

For the implementation details check out [recorder source
code](https://github.com/asciinema/asciinema).

## Playback

As the recording is a raw stream of text and control
sequences it can't be just played by incrementally printing text in proper
intervals. It requires interpretation of [ANSI escape code
sequences](http://en.wikipedia.org/wiki/ANSI_escape_code) in order to
correctly display color changes, cursor movement and printing text at proper
places on the screen.

The player comes with its own terminal emulator based on
[Paul Williams' parser for ANSI-compatible video terminals](https://vt100.net/emu/dec_ansi_parser).
It covers only the display part of the emulation as this is what the player is
about (input is handled by your terminal+shell at the time of recording anyway)
and its handling of escape sequences is fully compatible with most modern
terminal emulators like xterm, Gnome Terminal, iTerm, mosh etc.

The end result is a smooth animation with all text attributes (bold,
underline, inverse, ...) and 256 colors perfectly rendered.

For the implementation details check out [asciinema.org website source
code](https://github.com/asciinema/asciinema-server) and [player source
code](https://github.com/asciinema/asciinema-player).
