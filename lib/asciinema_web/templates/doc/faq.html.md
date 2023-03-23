# Frequently Asked Questions

## How is it pronounced?

_[as-kee-nuh-muh]_.

The word “asciinema” is a combination of English “ASCII” and Ancient Greek
“κίνημα” (kínēma, “movement”).

## Why am I getting `command not found` at the begining of the recording session?

When recording asciinema starts new shell instance (as indicated by `$SHELL`
environment variable) by default. It invokes `exec $SHELL`, which in most
cases translates to `exec /bin/bash` or `exec /bin/zsh`. This means the shell
runs as an "interactive shell", but **not as a "login shell"**.

If you have functions and/or other shell configuration defined in either
`.bash_profile`, `.zprofile` or `.profile` file they are not loaded unless the
shell is started as a login shell.

Some terminal emulators do that (passing "-l" option to the shell command-line),
some don't. asciinema doesn't.

Worry not, you have several options. You can:

* move this part of configuration to `.bashrc/.zshrc`,
* record with `asciinema rec -c "/bin/bash -l"` or,
* add the following setting to your `$HOME/.config/asciinema/config` file:

```
[record]
command = /bin/bash -l
```

## Why my shell prompt/theme isn't working during recording?

See above.

## Why some of my custom shell functions are not available during recording?

See above.

## Does it record the passwords I type during recording?

asciinema records only terminal output - everything that you can actually see
in a terminal window. It doesn't record input (keys pressed). Some
applications turn off "echo mode" when asking for a password, and because
the passwords are not visible they are not recorded. Some applications
display star characters instead of real characters and asciinema records
only "******". However, some applications don't have any precautions and
the actual password is visible to the user, and thus recorded by asciinema.

## Can I embed the asciicast player on my blog?

Yes, see [embedding docs](/docs/embedding).

## How can I delete my asciicast?

In order to delete your asciicast you need to associate your local API token
(which was assigned to the recorded asciicast) with the asciinema.org
account. Just run `asciinema auth` in your terminal and open the printed URL
in your browser.  Once you sign in you'll see a "Delete" link on your
asciicast's page.

## Can I have my own asciinema site instance?

Yes, you can set up your own asciinema site. The source code of the app that
runs asciinema.org is available
[here](https://github.com/asciinema/asciinema-server).

When you have the site up and running you can easily tell asciinema client to
use it by adding following setting to _~/.config/asciinema/config_ file:

    [api]
    url = http://asciinema.example.com

Alternatively, you can set `ASCIINEMA_API_URL` env variable:

    ASCIINEMA_API_URL=http://asciinema.example.com asciinema rec

## Can I edit/post-process the recorded asciicast?

Yes, if you know how to deal with [ansi escape
sequences](https://en.wikipedia.org/wiki/ANSI_escape_code). See documentation
for [asciicast
format](https://github.com/asciinema/asciinema/blob/main/doc/asciicast-v2.md).
