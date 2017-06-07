#!/bin/bash

mkdir -p tmp
bundle install
bundle exec rake db:setup
bundle exec rake
