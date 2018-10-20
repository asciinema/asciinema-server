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

FROM alpine:3.8

RUN apk update && \
  apk add --no-cache \
  ca-certificates \
  bash \
  elixir \
  erlang-xmerl \
  build-base \
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

# copy compiled a2png

COPY a2png/a2png.sh a2png/
COPY a2png/a2png.js a2png/
COPY a2png/page a2png/page
COPY --from=0 /app/a2png/main.js a2png/
COPY --from=0 /app/a2png/page/page.js a2png/page/

COPY a2png/package.json a2png/
COPY a2png/package-lock.json a2png/
RUN cd a2png && npm install
ENV A2PNG_BIN_PATH "/app/a2png/a2png.sh"

# service URLs

ENV DATABASE_URL "postgresql://postgres@postgres/postgres"
ENV REDIS_URL "redis://redis:6379"

# add setup & upgrade scripts

COPY docker/bin docker/bin
ENV PATH "/app/docker/bin:${PATH}"
COPY .iex.exs ./

VOLUME ["/app/uploads"]
CMD ["mix", "phx.server"]
ENV PORT 4000
EXPOSE 4000
