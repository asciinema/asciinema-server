#!/bin/bash

# Usage:
#   ASCIICAST_ID=666 COLS=80 LINES=20 COMMAND="df; df; df; sleep 10"
#   DELAY=1 THUMB_LINES=5 THUMB_COLS=10 ./tmux-save.sh

SESSION_NAME=asciiio-thumb-$ASCIICAST_ID

tmux new -s $SESSION_NAME -d -x $COLS -y $LINES "$COMMAND"
sleep $DELAY
tmux capture-pane -t $SESSION_NAME
tmux save-buffer - | tail -n $THUMB_LINES | ruby -e "ARGF.lines.each { |l| puts l[0...$THUMB_COLS] }"
