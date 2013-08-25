# ascii.io [![Build Status](https://secure.travis-ci.org/sickill/ascii.io.png?branch=master)](http://travis-ci.org/sickill/ascii.io)

ASCII.IO is the simplest way to record your terminal and share the recordings
with your fellow geeks. Simply record and upload your terminal session with
single command, and ASCII.IO will play it back in your browser.

This is the source code of ascii.io website and JS player. If you're looking
for ascii.io terminal recorder go here:
[sickill/ascii.io-cli](https://github.com/sickill/ascii.io-cli)

## Setup instructions

Below you'll find setup instructions in case you want to contribute, play with
it on your local machine or setup your own instance for your organization.

### 1. Install dependencies

ascii.io site is a Ruby on Rails application. You need to have following
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

    $ git clone git://github.com/sickill/ascii.io.git
    $ cd ascii.io

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

## Authors

* Marcin Kulik (sickill)
* Michał Wróbel (sparrovv)
