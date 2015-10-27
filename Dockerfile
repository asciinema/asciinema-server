FROM ubuntu:14.04
MAINTAINER Bartosz Ptaszynski <foobarto@gmail.com>

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

ENV RUBY_VERSION 2.1.7
EXPOSE 3000

# get ruby in the house
RUN mkdir /app && \
    apt-get update && \
    apt-get install -y \
      autoconf \
      build-essential \
      curl \
      git-core \
      libcurl4-openssl-dev \
      libffi-dev \
      libpq-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libtool \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      pkg-config \
      postgresql \
      python-software-properties \
      sendmail \
      software-properties-common \
      sqlite3 \
      zlib1g-dev

ENV PATH /usr/local/rbenv/bin:/usr/local/rbenv/plugins/ruby-build/bin:$PATH

# install ruby
RUN mkdir /usr/local/rbenv && \
    git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv && \
    git clone git://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build && \
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git /usr/local/rbenv/plugins/rbenv-gem-rehash && \
    rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    rbenv rehash

# get asciinema dependencies
RUN curl --silent --location https://deb.nodesource.com/setup_4.x | sudo bash - && \
    add-apt-repository ppa:tanguy-patte/phantomjs && \
    apt-get update && \
    apt-get install -y phantomjs nodejs && \
    rbenv exec gem install bundler

# get libtsm
RUN git clone git://people.freedesktop.org/~dvdhrm/libtsm /tmp/libtsm && \
    cd /tmp/libtsm && \
    git checkout libtsm-3 && \
    test -f ./configure || NOCONFIGURE=1 ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make && \
    sudo make install && \
    sudo ldconfig

# install asciinema
ADD . /app
WORKDIR /app

RUN rbenv local $RUBY_VERSION && \
    cd /app/src && \
    eval "$(rbenv init -)" && \
    make && \
    cd /app && \
    rm -f log/* && \
    bundle install && \
    mkdir -p tmp && \
    touch tmp/restart.txt

VOLUME ["/app/config", "/app/log"]

# 172.17.42.1 is the docker0 address
ENV DATABASE_URL "postgresql://postgres:mypass@172.17.42.1/asciinema"
ENV REDIS_URL "redis://172.17.42.1:6379"
ENV RAILS_ENV "development"
# when using Docker Toolbox/Virtualbox this is going to be your address
# set to whatever FQDN/address you want asciinema to advertise itself as
# for ex. asciinema.example.com
ENV HOST "192.168.99.100:3000"

ENTRYPOINT ["rbenv", "exec"]
CMD ["bundle", "exec", "rails", "server"]
# bundle exec rake db:setup
# budnle exec sidekiq  OR ruby start_sidekiq.rb (to start sidekiq with sendmail)
