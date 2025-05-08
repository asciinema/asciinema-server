defmodule Asciinema.Recordings.TextTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Recordings.Text

  describe "text/1" do
    test "returns plain text log of a recording" do
      asciicast = with_file(insert(:asciicast))

      text = Text.text(asciicast)

      assert text == """
             > # Welcome to asciinema!
             > # See how easy it is to record a terminal session
             > # First install the asciinema recorder
             > brew install asciinema
             ==> Downloading https://homebrew.bintray.com/bottles/asciinema-1.4.0.sierra.bottle.tar.gz
             ######################################################################## 100.0%
             ==> Pouring asciinema-1.4.0.sierra.bottle.tar.gz
             🍺  /usr/local/Cellar/asciinema/1.4.0: 30 files, 82.2KB
             > # Now start recording
             > asciinema rec
             ~ Asciicast recording started.
             ~ Hit Ctrl-D or type \"exit\" to finish.
             bash-3.2$ # I am in a new shell instance which is being recorded now
             bash-3.2$ sha1sum /etc/f* | tail -n 10 | lolcat -F 0.3
             da39a3ee5e6b4b0d3255bfef95601890afd80709  /etc/find.codes
             88dd3ea7ffcbb910fbd1d921811817d935310b34  /etc/fstab.hd
             442a5bc4174a8f4d6ef8d5ae5da9251ebb6ab455  /etc/ftpd.conf
             442a5bc4174a8f4d6ef8d5ae5da9251ebb6ab455  /etc/ftpd.conf.default
             d3e5fb0c582645e60f8a13802be0c909a3f9e4d7  /etc/ftpusers
             bash-3.2$ # To finish recording just exit the shell
             bash-3.2$ exit
             exit
             ~ Asciicast recording finished.
             ~ Press <Enter> to upload, <Ctrl-C> to cancel.

             https://asciinema.org/a/17648
             > # Open the above URL to view the recording
             > # Now install asciinema and start recording your own sessions
             > # Oh, and you can copy-paste from here
             > # Bye!
             """
    end
  end
end
