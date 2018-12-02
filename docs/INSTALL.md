_Note: This is guide for `development` branch. [See the version for latest stable release](https://github.com/asciinema/asciinema-server/blob/master/docs/INSTALL.md)._

# asciinema web app install guide

The only officially supported installation procedure of asciinema web app
is [Docker](https://www.docker.com/) based. You must have SSH access to a
64-bit Linux server with Docker support.

If you really, really want to install everything manually then look
at [Dockerfile](../Dockerfile) and [docker-compose.yml](../docker-compose.yml)
to see what's required by the app.

## Hmm, why Docker?

Hosting non-trivial web applications is complicated. Setting this one up
requires installation of fair number of system packages and build tools,
configuring monitoring of several processes, as well as configuring Nginx. Also,
you need PostgreSQL, Redis, and SMTP server.

With Docker, you get the battle tested configuration (similar to what's running
on asciinema.org), in a stable container, along with all required services
preconfigured.

It also makes upgrading to new versions much easier.

## Hardware Requirements

- modern single core CPU, dual core recommended
- 1 GB RAM minimum (with swap)
- 64 bit Linux compatible with Docker
- 10 GB disk space minimum

## Service Requirements

asciinema web app requires the following services:

- [Postgres 9.5+](http://www.postgresql.org/download/)
- [Redis 2.6+](http://redis.io/download)
- SMTP server

If you go with the provided [docker-compose.yml](../docker-compose.yml) file you
don't need to worry about these - they're included and already configured to
work with this app.

## Installation

This guide assumes you already
have [Docker engine](https://docs.docker.com/engine/)
and [docker-compose](https://docs.docker.com/compose/) running on the
installation host.

You don't have to use docker-compose to use asciinema web app Docker image. Feel
free to inspect `docker-compose.yml` file and run required services manually with
`docker run ...`. However, for the sake of simplicity and to minimize
configuration issues the rest of this guide is based on the provided/suggested
docker-compose configuration.

### Clone the repository

    git clone --recursive https://github.com/asciinema/asciinema-server.git
    cd asciinema-server
    git checkout master

It's recommended to create a new branch, to keep any customizations separate
from master branch and make upgrading safer:

    git checkout -b my-company master

### Edit config file

You need to create `.env.production` config file. The easiest is to use
provided [.env.production.sample](../.env.production.sample) as a template:

    cp .env.production.sample .env.production
    nano .env.production

There are several variables which have to be set, like `URL_HOST` and
`SECRET_KEY_BASE`. The rest is optional, and most likely used when you want to
use your own SMTP, PostgreSQL or Redis server.

#### Basic settings

Set `URL_SCHEME`, `URL_HOST` and `URL_PORT` to match the address the users are supposed to reach this instance at. For example:

    URL_SCHEME=http
    URL_HOST=asciinema.example.com
    URL_PORT=80

Ensure you set the nginx port in the docker-compose.yml file equal to what you specified for `URL_PORT`.

Set `SECRET_KEY_BASE` to long random string. Run `docker-compose run --rm phoenix
asciinema gen_secret` to obtain one.

#### HTTPS settings

To enable HTTPS (in addition to HTTP), make the following changes.

In the repository root, create a directory named `certs`.
Copy your SSL/TLS certificate and private key into this directory.

In `.env.production`, set

    URL_SCHEME=https
    URL_PORT=443

In `docker-compose.yml`, uncomment these two lines (they are marked in the file):

    - "443:443"
    - ./certs:/app/priv/certs

In `docker/nginx/asciinema.conf`, uncomment this section:

    listen 443 ssl;
    ssl_certificate     /app/priv/certs/<my-cert>.crt;
    ssl_certificate_key /app/priv/certs/<my-cert>.key;

Make sure to substitute the proper filenames for your certificate and private key files.

If you encounter problems, it may be helpful to run `docker exec -it asciinema_phoenix bash`
to enter a shell in the container, and then inspect the web server logs in `/var/log/nginx`.

#### SMTP settings

The app uses linked `namshi/smtp` container, which by default runs in "SMTP
Server" mode. Set `MAILNAME` to the outgoing mail hostname, for example, use the
same hostname as in `URL_HOST`.

You can configure it to act as GMail relay, Amazon SES relay or generic SMTP
relay. See
[namshi/docker-smtp README](https://github.com/namshi/docker-smtp/blob/master/README.md)
for details.

For example, to send emails through GMail add `GMAIL_USER` and `GMAIL_PASSWORD`
(most likely
[App Password](https://support.google.com/accounts/answer/185833?hl=en))
variables to the config file.

#### Database settings

`DATABASE_URL` and `REDIS_URL` point to linked `postgres` and `redis` containers
by default. You can set these so they point to your existing services. Look at
"Service Requirements" above for minimum versions supported.

### Specify volume mappings

The container has two volumes, for user uploads and for application logs. The
default `docker-compose.yml` maps them to the repository's `uploads` and `log`
directories, you may wish to put them somewhere else.

Likewise, the PostgreSQL and Redis images have data volumes that you may wish to
map somewhere where you know how to find them and back them up. By default
they're mapped inside repository's `volumes` directory.

### Initialize the database

You have the config file ready and the data volumes mapped. It's time to set up
the database.

Start PostgreSQL container (skip this if you use existing PostgreSQL server):

    docker-compose up -d postgres

Create database schema and seed it with initial data:

    docker-compose run --rm phoenix setup

### Create containers

The final step is to create the containers:

    docker-compose up -d

Check the status of newly created containers:

    docker ps -f 'name=asciinema_'

You should see `asciinema_phoenix`, `asciinema_postgres` and a few others listed.

Point your browser to `URL_HOST:URL_PORT` and enjoy your own asciinema hosting site!

## Using asciinema recorder with your instance

Once you have your instance running, point asciinema recorder to it by setting
API URL in `~/.config/asciinema/config` file as follows:

```ini
[api]
url = https://your.asciinema.host
```

Alternatively, you can set `ASCIINEMA_API_URL` environment variable:

    ASCIINEMA_API_URL=https://your.asciinema.host asciinema rec

## Upgrading

Pull latest Docker image:

    docker pull asciinema/asciinema-server

Pull latest configs from upstream and merge it into your branch:

    git fetch origin
    git merge origin/master

Upgrade containers:

    docker-compose up --no-start phoenix

Upgrade database:

    docker-compose run --rm phoenix upgrade

Start containers:

    docker-compose up -d

## Administrative tasks

Site admin can do the following administrative tasks:

- edit, delete any recording
- make recording a featured one
- make recording public/private

There isn't a dedicated admin UI, all of the above actions are done through the
gear dropdown available on asciicast's view page (below the player, on the
right).

### Making user an admin

To make user an admin, run the following command with the email address of
existing account:

    docker-compose run --rm phoenix asciinema admin_add email@example.com

To remove admin bit from a user, run:

    docker-compose run --rm phoenix asciinema admin_rm email@example.com

Both above commands allow passing multiple email adresses (as separate
arguments).

## Customizations

If the variables in `.env.production` file are not enough for your needs then
you can easily edit source code and rebuild the image.

Let's take max upload size as an example. We'll change it to 32MB. We need to
edit 2 files.

Switch to a new branch (or the one you created in "Clone the repository" step
earlier):

    git checkout -b my-company

First, edit `docker/nginx/asciinema.conf` file, applying this change:

```diff
-client_max_body_size 16m
+client_max_body_size 32m
```

Then, edit `lib/asciinema_web/endpoint.ex` file, applying this change:

```diff
-plug Plug.Parsers,
-    parsers: [:urlencoded, :multipart, :json],
-    pass: ["*/*"],
-    json_decoder: Poison
+plug Plug.Parsers,
+    parsers: [:urlencoded, :multipart, :json],
+    pass: ["*/*"],
+    json_decoder: Poison,
+    length: 32_000_000
```

Now, stop `phoenix` container:

    docker-compose stop phoenix

Rebuild the image:

    docker build -t asciinema/asciinema-server .

Start new `phoenix` container:

    docker-compose up phoenix -d

If all is good then commit your customization (so you can fetch and merge latest
version in the future):

    git add -A .
    git commit -m "Increased upload size limit to 32MB"
