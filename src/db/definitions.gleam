import based.{type DB}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import types/definition.{type Definition, Definition}
import types/error.{type Error, DbError, NotFoundError}
import types/id.{type Id}
import utils/formatters

pub fn get_all(db: DB) -> Result(List(Definition), Error) {
  "SELECT identifier
        , description
        , amount
        , frequency
        , start_date
        , end_date
   FROM definitions"
  |> based.new_query
  |> based.all(db, definition_decoder)
  |> result.map(fn(r) { r.rows })
  |> result.map_error(DbError)
}

pub fn get_one(id: Id(Definition), db: DB) -> Result(Definition, Error) {
  "SELECT identifier
        , description
        , amount
        , frequency
        , start_date
        , end_date
   FROM definitions
   WHERE identifier = $1"
  |> based.new_query
  |> based.with_values([based.string(id.unwrap(id))])
  |> based.all(db, definition_decoder)
  |> result.map_error(DbError)
  |> result.try(fn(r) {
    list.first(r.rows) |> result.replace_error(NotFoundError)
  })
}

pub fn upsert_definition(definition: Definition, db: DB) -> Result(Nil, Error) {
  use sql <- result.try(case get_one(definition.id, db) {
    Ok(_found) -> {
      Ok(
        "UPDATE definitions
       SET  description = $1
           ,amount = $2
           ,frequency = $3
           ,start_date = $4
           ,end_date = $5
       WHERE identifier = $6",
      )
    }
    Error(NotFoundError) -> {
      Ok(
        "INSERT INTO definitions(description, amount, frequency, start_date, end_date, identifier)
       VALUES($1, $2, $3, $4, $5, $6)",
      )
    }
    Error(e) -> Error(e)
  })

  sql
  |> based.new_query
  |> based.with_values([
    based.string(definition.description),
    based.float(definition.amount),
    based.string(definition.encode_frequency(definition.frequency)),
    based.string(formatters.format_date(definition.start_date)),
    definition.end_date
      |> option.map(fn(d) { d |> formatters.format_date |> based.string })
      |> option.unwrap(based.null()),
    based.string(id.unwrap(definition.id)),
  ])
  |> based.execute(db)
  |> result.map_error(DbError)
  |> result.replace(Nil)
}

fn definition_decoder(dyn: Dynamic) -> Result(Definition, DecodeErrors) {
  dynamic.decode6(
    Definition,
    dynamic.element(0, id.decoder),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.float),
    dynamic.element(3, definition.frequency_decoder),
    dynamic.element(4, definition.day_decoder),
    dynamic.element(5, dynamic.optional(definition.day_decoder)),
  )(dyn)
}
