# asciinema.org

[![Build Status](https://travis-ci.org/sickill/asciinema.org.png?branch=master)](https://travis-ci.org/sickill/asciinema.org)
[![Code Climate](https://codeclimate.com/github/sickill/asciinema.org.png)](https://codeclimate.com/github/sickill/asciinema.org)
[![Coverage Status](https://coveralls.io/repos/sickill/asciinema.org/badge.png)](https://coveralls.io/r/sickill/asciinema.org)

Record and share your terminal sessions, the right way.

Asciinema is a free and open source solution for recording the terminal
sessions and sharing them on the web.

This is the source code of asciinema.org (formerly ascii.io) website and JS
player. If you're looking for asciinema terminal recorder go here:
[sickill/asciinema](https://github.com/sickill/asciinema)

## Setup instructions

Below you'll find setup instructions in case you want to contribute, play with
it on your local machine or setup your own instance for your organization.

### 1. Install dependencies

asciinema.org site is a Ruby on Rails application. You need to have following
dependencies installed:

* Ruby 1.9.3+ (Ruby 2.0.0-p247 is recommended)

* bundler gem  
  `gem install bundler`

* PostgreSQL 8+ with libpq development headers  
  `sudo apt-get install postgresql libpq-dev` on Debian/Ubuntu

* libtsm  
  See [here](https://github.com/dvdhrm/libtsm) for installation instructions.
  If you don't install it now the setup script (point 4 below) will try to
  install it for you anyway.

### 2. Get the source code

Clone git repository:

    $ git clone git://github.com/sickill/asciinema.org.git
    $ cd asciinema.org

### 3. Prepare database config file

Copy *config/database.yml.example* to *config/database.yml*. Then set
database/user/password to whatever you prefer.

If database specified in database.yml doesn't exist then the following setup
task will create it (make sure database user is allowed to create new
databases).

### 4. Setup the app

Following script will install gem dependencies and setup database:

    $ ./script/setup

### 5. Run Rails server

    $ bundle exec rails server

### 6. Run the background job processor

The background job processor is needed for thumbnail generation.

    $ bundle exec sidekiq

## Contributing

If you want to contribute to this project check out
[Contributing](http://asciinema.org/contributing) page.

## Authors

Developed with passion by [Marcin Kulik](http://ku1ik.com) and great open
source [contributors](https://github.com/sickill/asciinema.org/contributors)

## Copyright

Copyright &copy; 2011-2014 Marcin Kulik. See LICENSE.txt for details.
