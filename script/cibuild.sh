#!/bin/bash

bundle exec rake db:create db:migrate --trace
bundle exec rake
