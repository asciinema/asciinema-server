FROM clojure:alpine

RUN mkdir /app
WORKDIR /app

# build vt

COPY vt/project.clj /app/vt/
RUN cd vt && lein deps

COPY vt/src /app/vt/src
COPY vt/resources /app/vt/resources
RUN cd vt && lein cljsbuild once main

FROM alpine:3.8

RUN apk update && \
  apk add --no-cache \
  ca-certificates \
  bash \
  elixir \
  erlang-xmerl \
  build-base \
  librsvg \
  ttf-dejavu \
  pngquant \
  nodejs \
  npm

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

ENV MIX_ENV "prod"

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

# copy compiled vt

COPY --from=0 /app/vt/main.js vt/
COPY vt/liner.js vt/

# add setup & upgrade scripts

COPY docker/bin docker/bin
COPY .iex.exs ./

# env

ENV PORT 4000
ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV REDIS_URL "redis://redis:6379"
ENV RSVG_FONT_FAMILY "Dejavu Sans Mono"
ENV PATH "/app/docker/bin:${PATH}"

VOLUME ["/app/uploads"]

CMD ["mix", "phx.server"]

EXPOSE 4000
