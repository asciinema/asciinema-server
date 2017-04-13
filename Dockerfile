FROM ubuntu:16.04
MAINTAINER Bartosz Ptaszynski <foobarto@gmail.com>
MAINTAINER Marcin Kulik <support@asciinema.org>

# A quickstart:
#
#     docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=mypass --name=postgres postgres
#     docker run -d -p 6379:6379 --name=redis redis
#     docker run --rm -e DATABASE_URL="postgresql://postgres:mypass@172.17.42.1/asciinema" foobarto/asciinema.org bundle exec rake db:setup
#     # starting sidekiq using the provided start_sidekiq.rb file will also start sendmail service if you don't want to use SMTP
#     # otherwise start sidekiq by starting: bundle exec sidekiq
#     docker run -d -e DATABASE_URL="postgresql://postgres:mypass@172.17.42.1/asciinema" foobarto/asciinema.org ruby start_sidekiq.rb
#     docker run -d -e DATABASE_URL="postgresql://postgres:mypass@172.17.42.1/asciinema" -p 3000:3000 foobarto/asciinema.org
#
# You can override the address/port that is sent in email with login token by passing HOST="host:port" environment variable when starting the web server.
#
# Assuming you are running Docker Toolbox and VirtualBox: go to http://192.168.99.100:3000/ and enjoy.

EXPOSE 3000

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
      libfontconfig1 \
      libpq-dev \
      libtool \
      libxml2-dev \
      libxslt1-dev \
      nodejs \
      pkg-config \
      ruby2.1 \
      ruby2.1-dev \
      sendmail \
      ttf-bitstream-vera

# autoconf, libtool and pkg-config for libtsm

RUN gem install bundler

ARG PHANTOMJS_VERSION=2.1.1

RUN wget --quiet -O /opt/phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
    tar xjf /opt/phantomjs.tar.bz2 -C /opt && \
    rm /opt/phantomjs.tar.bz2 && \
    ln -sf /opt/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/local/bin

# get libtsm
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

RUN mkdir -p /app/tmp /app/log
WORKDIR /app

ADD Gemfile* /app/
RUN bundle install

ADD a2png/project.clj /app/a2png/
RUN cd a2png && lein deps

ADD . /app

RUN cd src && make

RUN cd a2png && lein cljsbuild once main && lein cljsbuild once page

VOLUME ["/app/config", "/app/log", "/app/uploads"]

# 172.17.42.1 is the docker0 address
ENV DATABASE_URL "postgresql://postgres:mypass@172.17.42.1/asciinema"
ENV REDIS_URL "redis://172.17.42.1:6379"
ENV RAILS_ENV "development"
# when using Docker Toolbox/Virtualbox this is going to be your address
# set to whatever FQDN/address you want asciinema to advertise itself as
# for ex. asciinema.example.com
ENV HOST "localhost:3000"

CMD ["bundle", "exec", "rails", "server"]
# bundle exec rake db:setup
# bundle exec sidekiq  OR ruby start_sidekiq.rb (to start sidekiq with sendmail)
