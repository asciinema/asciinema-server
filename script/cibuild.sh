#!/bin/bash

./script/setup
bundle exec rake && ./script/check-style.sh
