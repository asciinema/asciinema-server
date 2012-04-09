# ascii.io [![Build Status](https://secure.travis-ci.org/sickill/ascii.io.png?branch=master)](http://travis-ci.org/sickill/ascii.io)

This is the source code of ascii.io website/player. If you look for ascii.io command line
recorder go here: https://github.com/sickill/ascii.io-cli

Below are setup instructions in case you want to contribute and/or play with it
on your local machine.

## Requirements

ascii.io site is a Ruby on Rails application. You should have following
installed:

* ruby 1.9.2+ (``rvm install 1.9.2``)
* bundler (``gem install bundler``)

For thumbnail generation you need also:

* tmux
* scriptreplay (Linux only via ``script`` package. OSX users: sorry, your script
  command is crippled anyway)

## Setup

### Clone

    $ git clone git://github.com/sickill/ascii.io.git
    $ cd ascii.io

### Install gem dependencies

    $ bundle install

### Setup DB

* copy *config/database.yml.example* to *config/database.yml* and set adapter
  to what you prefer,
* run ``bundle exec db:setup``

### Start

* start webserver with ``script/rails s``
* (optional) start background job worker for thumbnail generation with
  ``bundle exec sidekiq``

## Authors

* Marcin Kulik (sickill)
* Michał Wróbel (sparrovv)
