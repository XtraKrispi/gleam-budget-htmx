FROM ghcr.io/gleam-lang/gleam:v1.2.1-elixir as build
RUN mix local.hex --force
WORKDIR /src
COPY . /src

RUN gleam export erlang-shipment

RUN cp -r build/erlang-shipment/. /app

FROM ghcr.io/gleam-lang/gleam:v1.2.1-elixir as deploy
COPY --from=build /app /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]