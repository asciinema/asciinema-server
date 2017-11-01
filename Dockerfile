FROM clojure:alpine

RUN mkdir /app
WORKDIR /app

# build vt

COPY vt/project.clj /app/vt/
RUN cd vt && lein deps

COPY vt/src /app/vt/src
COPY vt/resources /app/vt/resources
RUN cd vt && lein cljsbuild once main

# build a2png

COPY a2png/project.clj /app/a2png/
RUN cd a2png && lein deps

COPY a2png/src /app/a2png/src
COPY a2png/asciinema-player /app/a2png/asciinema-player
RUN cd a2png && lein cljsbuild once main && lein cljsbuild once page

FROM ubuntu:16.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=node_6.x
ARG DISTRO=xenial

RUN apt-get update && \
    apt-get install -y wget software-properties-common apt-transport-https && \
    add-apt-repository ppa:brightbox/ruby-ng && \
    echo "deb https://deb.nodesource.com/$NODE_VERSION $DISTRO main" >/etc/apt/sources.list.d/nodesource.list && \
    echo "deb https://packages.erlang-solutions.com/ubuntu $DISTRO contrib" >/etc/apt/sources.list.d/esl.list && \
    wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    wget --quiet -O - https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y \
      build-essential \
      elixir=1.4.2-1 \
      esl-erlang=1:19.3.6 \
      git-core \
      libfontconfig1 \
      libpq-dev \
      libxml2-dev \
      libxslt1-dev \
      nginx \
      nodejs \
      ruby2.1 \
      ruby2.1-dev \
      supervisor \
      ttf-bitstream-vera \
      tzdata

# Packages required for:
#   libfontconfig1 for PhantomJS
#   ttf-bitstream-vera for a2png

# install Bundler and SASS

RUN gem install bundler sass

# install Hex and Rebar

ENV LANG=C.UTF-8

RUN mix local.hex --force && mix local.rebar --force

# install PhantomJS

ARG PHANTOMJS_VERSION=2.1.1

RUN wget --quiet -O /opt/phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
    tar xjf /opt/phantomjs.tar.bz2 -C /opt && \
    rm /opt/phantomjs.tar.bz2 && \
    ln -sf /opt/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/local/bin

# install asciinema

ENV RAILS_ENV "production"
ENV MIX_ENV "prod"

RUN mkdir -p /app/tmp /app/log
WORKDIR /app

# install gems

COPY Gemfile* /app/
RUN bundle install --deployment --without development test --jobs 10 --retry 5

# copy compiled vt

COPY --from=0 /app/vt/main.js /app/vt/
COPY vt/liner.js /app/vt/

# copy compiled a2png

COPY a2png/a2png.sh /app/a2png/
COPY a2png/a2png.js /app/a2png/
COPY a2png/page /app/a2png/page
COPY --from=0 /app/a2png/main.js /app/a2png/
COPY --from=0 /app/a2png/page/page.js /app/a2png/page/

COPY a2png/package.json /app/a2png/
RUN cd a2png && npm install

# service URLs

ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV REDIS_URL "redis://redis:6379"

# add Ruby source files

COPY config/*.rb /app/config/
COPY config/*.yml /app/config/
COPY config/environments /app/config/environments
COPY config/initializers /app/config/initializers
COPY config/locales /app/config/locales
COPY lib/*.rb /app/lib/
COPY lib/authentication /app/lib/authentication
COPY lib/tasks /app/lib/tasks
COPY public /app/public
COPY vendor /app/vendor
COPY config.ru /app/
COPY Rakefile /app/
COPY app /app/app

# compile assets with assets pipeline

RUN bundle exec rake assets:precompile

# install hex packages

COPY mix.* /app/
RUN mix deps.get --only prod && mix deps.compile

# install brunch & co

COPY assets/package.json /app/assets/
RUN cd assets && npm install

# compile assets with brunch and generate digest file

COPY assets /app/assets
RUN cd assets && node_modules/brunch/bin/brunch build --production
RUN mix phoenix.digest

# add Elixir source files

COPY config/*.exs /app/config/
COPY lib/*.ex /app/lib
COPY lib/asciinema /app/lib/asciinema
COPY lib/asciinema_web /app/lib/asciinema_web
COPY priv/gettext /app/priv/gettext
COPY priv/repo /app/priv/repo
COPY priv/welcome.json /app/priv/welcome.json

# compile Elixir app

RUN mix compile

# install smtp configuration

COPY docker/asciinema.yml /app/config/asciinema.yml

# configure Nginx

COPY docker/nginx/asciinema.conf /etc/nginx/sites-available/default

# configure Supervisor

RUN mkdir -p /var/log/supervisor
COPY docker/supervisor/asciinema.conf /etc/supervisor/conf.d/asciinema.conf

# add setup script

COPY docker/bin /app/docker/bin
ENV PATH "/app/docker/bin:${PATH}"

ENV A2PNG_BIN_PATH "/app/a2png/a2png.sh"

VOLUME ["/app/log", "/app/uploads", "/cache"]

CMD ["/usr/bin/supervisord"]

EXPOSE 80
EXPOSE 3000
EXPOSE 4000
