FROM ubuntu:16.04
MAINTAINER Bartosz Ptaszynski <foobarto@gmail.com>
MAINTAINER Marcin Kulik <support@asciinema.org>

# A quickstart:
#
#     docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=mypass --name=postgres postgres
#     docker run -d -p 6379:6379 --name=redis redis
#     docker run --rm -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" asciinema/asciinema.org bundle exec rake db:setup
#     docker run -d -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" asciinema/asciinema.org bundle exec sidekiq
#     docker run -d -e DATABASE_URL="postgresql://postgres:mypass@postgres/asciinema" -p 3000:80 asciinema/asciinema.org
#
# You can override the address/port that is sent in email with login token by passing HOST="host:port" environment variable when starting the web server.

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=node_6.x
ARG DISTRO=xenial

RUN apt-get update && \
    apt-get install -y wget software-properties-common apt-transport-https && \
    add-apt-repository ppa:brightbox/ruby-ng && \
    echo "deb https://deb.nodesource.com/$NODE_VERSION $DISTRO main" >/etc/apt/sources.list.d/nodesource.list && \
    wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    apt-get update && \
    apt-get install -y \
      autoconf \
      build-essential \
      git-core \
      imagemagick \
      libfontconfig1 \
      libpq-dev \
      libtool \
      libxml2-dev \
      libxslt1-dev \
      nginx \
      nodejs \
      pkg-config \
      ruby2.1 \
      ruby2.1-dev \
      supervisor \
      ttf-bitstream-vera \
      tzdata

# Packages required for:
#   autoconf, libtool and pkg-config for libtsm
#   libfontconfig1 for PhantomJS
#   ttf-bitstream-vera for a2png
#   imagemagick (identify) for PNG generator (Ruby)

# install Bundler

RUN gem install bundler

# install PhantomJS

ARG PHANTOMJS_VERSION=2.1.1

RUN wget --quiet -O /opt/phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
    tar xjf /opt/phantomjs.tar.bz2 -C /opt && \
    rm /opt/phantomjs.tar.bz2 && \
    ln -sf /opt/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/local/bin

# install libtsm

RUN git clone https://github.com/asciinema/libtsm.git /tmp/libtsm && \
    cd /tmp/libtsm && \
    git checkout asciinema && \
    test -f ./configure || NOCONFIGURE=1 ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    ldconfig && \
    rm -rf /tmp/libtsm

# install JDK

RUN wget --quiet -O /opt/jdk-8u111-linux-x64.tar.gz --no-check-certificate --no-cookies --header 'Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz && \
    tar xzf /opt/jdk-8u111-linux-x64.tar.gz -C /opt && \
    rm /opt/jdk-8u111-linux-x64.tar.gz && \
    update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_111/bin/java 1000

# install leiningen

RUN wget --quiet -O /usr/local/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein && \
    chmod a+x /usr/local/bin/lein

ARG LEIN_ROOT=yes

# install asciinema

ENV RAILS_ENV "production"

RUN mkdir -p /app/tmp /app/log
WORKDIR /app

COPY Gemfile* /app/
RUN bundle install --deployment --without development test

COPY a2png/project.clj /app/a2png/
RUN cd a2png && lein deps

COPY a2png /app/a2png
RUN cd a2png && lein cljsbuild once main && lein cljsbuild once page

COPY . /app

ENV DATABASE_URL "postgresql://postgres:mypass@postgres/asciinema"
ENV REDIS_URL "redis://redis:6379"

RUN cd src && make
RUN bundle exec rake assets:precompile
COPY docker/asciinema.yml /app/config/asciinema.yml

# configure Nginx

COPY docker/nginx/asciinema.conf /etc/nginx/sites-available/default

# configure Supervisor

RUN mkdir -p /var/log/supervisor
COPY docker/supervisor/asciinema.conf /etc/supervisor/conf.d/asciinema.conf

VOLUME ["/app/log", "/app/uploads"]

ENV HOST "localhost:3000"

CMD ["/usr/bin/supervisord"]
# bundle exec rake db:setup
# bundle exec sidekiq

EXPOSE 80
