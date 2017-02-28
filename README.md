# asciinema.org

[![Build Status](https://travis-ci.org/asciinema/asciinema.org.svg?branch=master)](https://travis-ci.org/asciinema/asciinema.org)
[![Code Climate](https://codeclimate.com/github/asciinema/asciinema.org/badges/gpa.svg)](https://codeclimate.com/github/asciinema/asciinema.org)
[![Coverage Status](https://coveralls.io/repos/asciinema/asciinema.org/badge.svg)](https://coveralls.io/r/asciinema/asciinema.org)

Record and share your terminal sessions, the right way.

asciinema is a free and open source solution for recording terminal sessions
and sharing them on the web.

This is the source code of asciinema.org website. You can find asciinema's
terminal recorder at
[asciinema/asciinema](https://github.com/asciinema/asciinema) and asciinema
player at
[asciinema/asciinema-player](https://github.com/asciinema/asciinema-player).

## Setup instructions

Below you'll find setup instructions in case you want to contribute, play with
it on your local machine, or setup your own instance for private use or for
your organization.

### Quickstart Using Docker Compose

Required:
  - [Docker](https://docs.docker.com/engine/getstarted/step_one/#step-1-get-docker)
  - [docker-compose 1.5+](https://docs.docker.com/compose/install/)
```bash
$ wget https://raw.githubusercontent.com/asciinema/asciinema.org/master/docker-compose.yml
$ docker-compose up -d asciinema
$ docker-compose run --rm db_init

```

You can override the address/port that is sent in email with login token by passing HOST="host:port" environment variable when starting the web server.

Assuming you are running Docker Toolbox and VirtualBox: go to http://192.168.99.100:3000/ and enjoy.

### Manual setup

#### 1. Install dependencies

asciinema.org site is a Ruby on Rails application. You need to have following
dependencies installed:

* Ruby 2.0+ (Ruby 2.1 is recommended)

* bundler gem  
  `gem install bundler`

* PostgreSQL 8+ with libpq development headers  
  `sudo apt-get install postgresql libpq-dev` on Debian/Ubuntu

* asciinema's libtsm fork (`asciinema` branch)  
  See [here](https://github.com/asciinema/libtsm/blob/asciinema/README) for installation instructions.
  If you don't install it now the setup script (point 4 below) will try to
  install it for you anyway.

* phantomjs 2.0+  
  `sudo add-apt-repository ppa:tanguy-patte/phantomjs && sudo apt-get update && sudo apt-get install phantomjs`

#### 2. Get the source code

Clone git repository:

```bash
$ git clone git://github.com/asciinema/asciinema.org.git
$ cd asciinema.org
```

#### 3. Prepare database config file

Copy *config/database.yml.example* to *config/database.yml*. Then set
database/user/password to whatever you prefer.

If database specified in database.yml doesn't exist then the following setup
task will create it (make sure database user is allowed to create new
databases).

#### 4. Setup the app

Following script will install gem dependencies and setup database:

```bash
$ ./script/setup
```

#### 5. Run Rails server

```bash
$ bundle exec rails server
```

#### 6. Run the background job processor

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

Copyright &copy; 2011-2016 Marcin Kulik. See LICENSE.txt for details.
