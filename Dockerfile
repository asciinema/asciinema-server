ARG ALPINE_VERSION=3.17.0
ARG ERLANG_OTP_VERSION=25.2.2
ARG ELIXIR_VERSION=1.14.3

## Release building image

# https://github.com/hexpm/bob#docker-images
FROM docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_OTP_VERSION}-alpine-${ALPINE_VERSION} as builder

ARG MIX_ENV=prod
ENV ERL_FLAGS="+JPperf true"

WORKDIR /opt/app

RUN apk upgrade && \
  apk add \
    nodejs \
    npm \
    rust \
    cargo \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

COPY native native/
RUN cd native/vt_nif && cargo build -r

COPY mix.* ./
RUN mix do deps.get --only prod, deps.compile

COPY assets/ assets/
RUN cd assets && \
  npm install && \
  env NODE_OPTIONS=--openssl-legacy-provider npm run deploy

COPY config/config.exs config/
COPY config/prod.exs config/

RUN mix phx.digest

COPY config/*.exs config/
COPY lib lib/
COPY priv priv/

# recompile sentry with our source code
RUN mix deps.compile sentry --force

COPY rel rel/

RUN mix release

# Final image

FROM docker.io/alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
  libstdc++ \
  tini \
  bash \
  ca-certificates \
  rsvg-convert \
  ttf-dejavu \
  pngquant

WORKDIR /opt/app

COPY --from=builder /opt/app/_build/prod/rel/asciinema .
RUN chgrp -R 0 /opt/app && chmod -R g=u /opt/app
COPY .iex.exs .

ENV PORT 4000
ENV ADMIN_BIND_ALL 1
ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV RSVG_FONT_FAMILY "Dejavu Sans Mono"
ENV PATH "/opt/app/bin:${PATH}"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/opt/app/bin/server"]

EXPOSE 4000
