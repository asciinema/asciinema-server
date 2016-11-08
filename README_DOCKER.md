Please read the [full setup](README.md) to understand the components involved.



### Using Docker

```bash
$ docker-compose up -d

$ docker-compose logs
```


Get the ip of the docker host and port.  If you're using docker-machine you could do

```docker-machine ip default```

otherwise you could do


``` docker inspect --format '{{ .NetworkSettings.IPAddress }}' asciinemaorg_asciinema_1 ```

to get the IP. You'll need this when setting up your CLI tool to point at it.

### Using the asciinema server 

Assuming you've installed the CLI tool, 

Edit the file ```~/.config/asciinema/config``` to have your host in there.  Please ensure that you have an auth token. 

Note that if you have an older version of asciinema it may have written to ```~/.asciinema/config``` and you'll need to get your token from there.


Run ```asciinema``` once if you haven't already to generate a token.  Now you can add your private server to it.



The file should in the end looks something like

```
[api]
token = 62398be2-16e4-476b-ae31-2806ca643e29
url = http://localhost:3000
```

now run 

```bash
$ asciinema auth
Open the following URL in a browser to register your API token and assign any recorded asciicasts to your profile:
http://localhost:3000/connect/62398be2-16e4-476b-ae31-2806ca643e29

```

And go the url in question.

You'll be prompted for an email address to which the server will send an authorization token.  Please note that this email is very likely to go into your spam folder :)

Follow that link and start recording



$ docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=mypass --name=postgres postgres
$ docker run -d -p 6379:6379 --name=redis redis
$ docker run --rm --link postgres:postgres -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" asciinema/asciinema.org bundle exec rake db:setup
# starting sidekiq using the provided start_sidekiq.rb file will also start sendmail service if you don't want to use SMTP
# otherwise start sidekiq by starting: bundle exec sidekiq
$ docker run -d --link postgres:postgres -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" asciinema/asciinema.org ruby  start_sidekiq.rb
$ docker run -d --link postgres:postgres -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" -p 3000:3000 asciinema/asciinema.org
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

## Contributing

If you want to contribute to this project check out
[Contributing](http://asciinema.org/contributing) page.

## Authors

Developed with passion by [Marcin Kulik](http://ku1ik.com) and great open
source [contributors](https://github.com/asciinema/asciinema.org/contributors)

## Copyright

Copyright &copy; 2011-2016 Marcin Kulik. See LICENSE.txt for details.
