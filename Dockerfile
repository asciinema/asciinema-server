## VT building image

FROM clojure:alpine AS vt

RUN mkdir /app
WORKDIR /app

COPY vt/project.clj /app/vt/
RUN cd vt && lein deps

COPY vt/src /app/vt/src
COPY vt/resources /app/vt/resources
RUN cd vt && lein cljsbuild once main

## Release building image

FROM elixir:1.6.6-alpine AS builder

ARG MIX_ENV=prod

WORKDIR /opt/app

RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    nodejs \
    npm \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

COPY assets/package.json assets/
COPY assets/package-lock.json assets/
RUN cd assets && npm install

COPY mix.* ./
RUN mix do deps.get --only prod, deps.compile

COPY assets/ assets/
RUN cd assets && npm run deploy
RUN mix phx.digest

COPY config/*.exs config/
COPY lib lib/
COPY priv priv/
RUN mix compile

COPY --from=vt /app/vt/main.js priv/vt/
COPY vt/liner.js priv/vt/

COPY rel rel/

RUN \
  mkdir -p /opt/built && \
  mix release --verbose && \
  cp _build/${MIX_ENV}/rel/asciinema/releases/0.0.1/asciinema.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf asciinema.tar.gz && \
  rm asciinema.tar.gz

## Final image

FROM alpine:3.8

RUN apk update && \
  apk add --no-cache \
  bash \
  librsvg \
  ttf-dejavu \
  pngquant \
  nodejs

WORKDIR /opt/app

COPY --from=builder /opt/built .
COPY config/custom.exs.sample /opt/app/etc/custom.exs
COPY .iex.exs .
COPY docker/bin/ bin/

ENV PORT 4000
ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV REDIS_URL "redis://redis:6379"
ENV RSVG_FONT_FAMILY "Dejavu Sans Mono"
ENV PATH "/opt/app/bin:${PATH}"

VOLUME /opt/app/uploads
VOLUME /opt/app/cache

CMD trap 'exit' INT; /opt/app/bin/asciinema foreground

EXPOSE 4000
