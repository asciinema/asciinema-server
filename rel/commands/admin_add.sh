#!/bin/sh

release_ctl eval --mfa "Mix.Tasks.Asciinema.Admin.Add.run/1" --argv -- "$@"
