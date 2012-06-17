#!/bin/bash

bundle exec cane --no-doc --abc-max 17 --abc-glob '{app,lib,spec}/**/*.rb' --style-glob '{app,lib,spec}/**/*.rb' && \
bundle exec tailor lib && bundle exec tailor spec
