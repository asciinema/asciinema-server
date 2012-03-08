#!/bin/bash

bundle exec rake db:create db:migrate
bundle exec rake && \
  bundle exec cane --no-doc --abc-glob '{app,lib,spec}/**/*.rb' --style-glob '{app,lib,spec}/**/*.rb' && \
  bundle exec tailor app && bundle exec tailor lib && bundle exec tailor spec
