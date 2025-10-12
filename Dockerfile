
# Build Elixir Release
FROM elixir:1.15 AS build

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

COPY mix.exs mix.lock ./
# COPY config ./config
RUN mix deps.get

COPY lib ./lib

RUN mix compile

# Run
FROM elixir:1.15-slim

WORKDIR /app

COPY --from=build /root/.mix /root/.mix

COPY --from=build /app /app

EXPOSE 8080

CMD ["mix", "run", "--no-halt"]
