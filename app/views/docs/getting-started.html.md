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

## 3. Create your profile (optional)

If you want your recordings to be assigned to your asciinema profile run the
following command:

    asciinema auth

If you skip this step now, you can run the above command later and all
previously recorded asciicasts will automatically get assigned to your
profile.

NOTE: To be able to edit/delete your recordings you have to assign them to
your profile.
