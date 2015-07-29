# asciinema.org

[![Build Status](https://travis-ci.org/asciinema/asciinema.org.svg?branch=master)](https://travis-ci.org/asciinema/asciinema.org)
[![Code Climate](https://codeclimate.com/github/asciinema/asciinema.org/badges/gpa.svg)](https://codeclimate.com/github/asciinema/asciinema.org)
[![Coverage Status](https://coveralls.io/repos/asciinema/asciinema.org/badge.svg)](https://coveralls.io/r/asciinema/asciinema.org)

Record and share your terminal sessions, the right way.

asciinema is a free and open source solution for recording terminal sessions
and sharing them on the web.

This is the source code of asciinema.org website. If you're looking for
asciinema's terminal recorder go here:
[asciinema/asciinema](https://github.com/asciinema/asciinema)

## Setup instructions

Below you'll find setup instructions in case you want to contribute, play with
it on your local machine, or setup your own instance for private use or for
your organization.

### 1. Install dependencies

asciinema.org site is a Ruby on Rails application. You need to have following
dependencies installed:

* Ruby 2.0+ (Ruby 2.1 is recommended)

* bundler gem  
  `gem install bundler`

* PostgreSQL 8+ with libpq development headers  
  `sudo apt-get install postgresql libpq-dev` on Debian/Ubuntu

* libtsm  
  See [here](http://cgit.freedesktop.org/~dvdhrm/libtsm/tree/README) for installation instructions.
  If you don't install it now the setup script (point 4 below) will try to
  install it for you anyway.

* phantomjs 2.0+  
  `sudo add-apt-repository ppa:tanguy-patte/phantomjs && sudo apt-get update && sudo apt-get install phantomjs`

### 2. Get the source code

Clone git repository:

```bash
$ git clone git://github.com/asciinema/asciinema.org.git
$ cd asciinema.org
```

### 3. Prepare database config file

Copy *config/database.yml.example* to *config/database.yml*. Then set
database/user/password to whatever you prefer.

If database specified in database.yml doesn't exist then the following setup
task will create it (make sure database user is allowed to create new
databases).

### 4. Setup the app

Following script will install gem dependencies and setup database:

```bash
$ ./script/setup
```

### 5. Run Rails server

```bash
$ bundle exec rails server
```

### 6. Run the background job processor

The background job processor is needed for asciicast pre-processing and
thumbnail generation.

```bash
$ bundle exec sidekiq
```

## Update instructions

### 1. Update the code
```bash
$ git pull
```

### 2. Update and install required dependencies
```bash
$ bundle install
```

### 3. Run the database migrations 
```bash
$ bundle exec rake db:migrate RAILS_ENV=development
```

### 4. Run the asciinema again
```bash
$ bundle exec rails server
```

### 5. Run the background job processor

The background job processor is needed for asciicast pre-processing and
thumbnail generation.

```bash
$ bundle exec sidekiq
```

## Contributing

If you want to contribute to this project check out
[Contributing](http://asciinema.org/contributing) page.

## Authors

Developed with passion by [Marcin Kulik](http://ku1ik.com) and great open
source [contributors](https://github.com/asciinema/asciinema.org/contributors)

## Copyright

Copyright &copy; 2011-2015 Marcin Kulik. See LICENSE.txt for details.
