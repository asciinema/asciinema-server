<% content_for(:title, 'Configuration file') %>

# Configuration file

asciinema uses a config file to keep API token and user settings. In most cases
the location of this file is `$HOME/.config/asciinema/config`.

When you first run `asciinema`, local API token is generated (UUID) and saved in the
file (unless the file already exists). It looks like this:

    [api]
    token = d5a2dce4-173f-45b2-a405-ac33d7b70c5f

There are several options you can set in this file. Here's a config with all
available options set:

    [api]
    token = d5a2dce4-173f-45b2-a405-ac33d7b70c5f
    url = https://asciinema.example.com

    [record]
    command = /bin/bash -l
    maxwait = 2
    yes = true

    [play]
    maxwait = 1

The options in `[api]` section are related to API location and authentication.
To tell asciinema recorder to use your own asciinema site instance rather than
the default one (asciinema.org), you can set `url` option. API URL can also be
passed via `ASCIINEMA_API_URL` environment variable.

The options in `[record]` and `[play]` sections have the same meaning as the
options you pass to `asciinema rec`/`asciinema play` command (see [Usage](<%= docs_path(:usage) %>)). If you happen to
often use either `-c`, `-w` or `-y` with these commands then consider saving it
as a default in the config file.

## Configuration file locations

In fact, the following locations are checked for the presence of the config
file (in the given order):

* `$ASCIINEMA_CONFIG_HOME/config` - if you have set `$ASCIINEMA_CONFIG_HOME`
* `$XDG_CONFIG_HOME/asciinema/config` - on Linux, `$XDG_CONFIG_HOME` usually points to `$HOME/.config/`
* `$HOME/.config/asciinema/config` - in most cases it's here
* `$HOME/.asciinema/config` - created by asciinema versions prior to 1.1

The first one which is found is used.
