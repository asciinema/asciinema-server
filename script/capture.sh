#!/bin/bash

# Usage:
#   ASCIICAST_ID=666 COLS=80 LINES=20 COMMAND="df; df; df; sleep 10"
#   DELAY=1 ./tmux-save.sh

set -e

unset TMUX

SESSION_NAME=asciiio-thumb-$ASCIICAST_ID-`date +'%s'`

tmux new -s $SESSION_NAME -d -x $COLS -y $LINES "$COMMAND"
sleep $DELAY
tmux capture-pane -t $SESSION_NAME
tmux save-buffer -
tmux kill-session -t $SESSION_NAME &>/dev/null
