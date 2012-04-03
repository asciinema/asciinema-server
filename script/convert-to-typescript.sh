#!/bin/bash

in_data_file="$1"
in_timing_file="$2"

out_data_file="$3"
out_timing_file="$4"

echo '# Foo' >$out_data_file
bzip2 -c -d $in_data_file >>$out_data_file

(echo 0.0; bzip2 -c -d $in_timing_file | awk '{ print $2; print $1 }' | head -n -1) | xargs -L 2 echo >$out_timing_file
