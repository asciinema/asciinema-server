# Configuration file

You can configure asciinema by creating config file at
`$HOME/.config/asciinema/config`.

Configuration is split into sections (`[api]`, `[record]`, `[play]`). Here's a
list of all available options for each section:

```ini
[api]

; API server URL, default: https://asciinema.org
; If you run your own instance of asciinema-server then set its address here
; It can also be overriden by setting ASCIINEMA_API_URL environment variable
url = https://asciinema.example.com

[record]

; Command to record, default: $SHELL
command = /bin/bash -l

; Enable stdin (keyboard) recording, default: no
stdin = yes

; List of environment variables to capture, default: SHELL,TERM
env = SHELL,TERM,USER

; Limit recorded terminal inactivity to max n seconds, default: off
idle_time_limit = 2

; Answer "yes" to all interactive prompts, default: no
yes = true

; Be quiet, suppress all notices/warnings, default: no
quiet = true

[play]

; Playback speed (can be fractional), default: 1
speed = 2

; Limit replayed terminal inactivity to max n seconds, default: off
idle_time_limit = 1
```

A very minimal config file could look like that:

```ini
[record]
idle_time_limit = 2
```

Config directory location can be changed by setting `$ASCIINEMA_CONFIG_HOME`
environment variable.

If `$XDG_CONFIG_HOME` is set on Linux then asciinema uses
`$XDG_CONFIG_HOME/asciinema` instead of `$HOME/.config/asciinema`.

> asciinema versions prior to 1.1 used `$HOME/.asciinema`. If you have it
> there you should `mv $HOME/.asciinema $HOME/.config/asciinema`.
