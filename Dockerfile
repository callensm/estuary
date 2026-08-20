FROM elixir:1.20-alpine AS builder

ENV MIX_ENV=prod

WORKDIR /estuary

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix deps.get --only prod

COPY lib/ lib/
RUN mix release

FROM elixir:1.20-alpine AS production

ENV MIX_ENV=prod

COPY --from=builder /estuary/_build/prod/rel/estuary /estuary

WORKDIR /estuary

CMD ["bin/estuary", "start"]
