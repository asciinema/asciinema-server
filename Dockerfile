ARG ALPINE_VERSION=3.11.6
ARG ERLANG_OTP_VERSION=22.3.4.3
ARG ELIXIR_VERSION=1.10.4

## Release building image

# https://github.com/hexpm/bob#docker-images
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_OTP_VERSION}-alpine-${ALPINE_VERSION} as builder

ARG MIX_ENV=prod

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

COPY mix.* ./
RUN mix do deps.get --only prod, deps.compile

COPY assets/ assets/
RUN cd assets && \
  npm install && \
  npm run deploy

RUN mix phx.digest

COPY config/*.exs config/
COPY lib lib/
COPY priv priv/
COPY native native/

# recompile sentry with our source code
RUN mix deps.compile sentry --force

COPY rel rel/
RUN mix release

# Final image

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
  bash \
  ca-certificates \
  librsvg \
  ttf-dejavu \
  pngquant

WORKDIR /opt/app

COPY --from=builder /opt/app/_build/prod/rel/asciinema .
COPY .iex.exs .

ENV PORT 4000
ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV REDIS_URL "redis://redis:6379"
ENV RSVG_FONT_FAMILY "Dejavu Sans Mono"
ENV PATH "/opt/app/bin:${PATH}"

VOLUME /opt/app/uploads
VOLUME /opt/app/cache

CMD exec /opt/app/bin/asciinema start

EXPOSE 4000
