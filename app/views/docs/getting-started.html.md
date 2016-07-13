<% content_for(:title, 'Getting started') %>

# Getting started

## 1. Install the recorder

<%= render partial: "docs/quick_install" %>

## 2. Record

To start recording run the following command:

    asciinema rec

This spawns a new shell instance and records all terminal output.
When you're ready to finish simply exit the shell either by typing `exit` or
hitting <kbd>Ctrl-D</kdb>.

See [usage instructions](<%= docs_path(:usage) %>) to learn about all commands and options.

## 3. Manage your recordings (optional)

If you want to manage your recordings on asciinema.org (set title/description,
delete etc) you need to authenticate. Run the following command and open
displayed URL in your web browser:

    asciinema auth

If you skip this step now, you can run the above command later and all
previously recorded asciicasts will automatically get assigned to your
profile.
