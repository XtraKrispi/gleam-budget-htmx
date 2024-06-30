import based.{type DB}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import types/definition.{type Definition, Definition}
import types/error.{type Error, DbError, NotFoundError}
import types/id.{type Id}
import types/user.{type Email}
import utils/decoders
import utils/formatters

pub fn get_all(email: Email, db: DB) -> Result(List(Definition), Error) {
  "SELECT d.identifier
        , d.description
        , d.amount
        , d.frequency
        , d.start_date
        , d.end_date
        , d.is_automatic_withdrawal
   FROM definitions d
   JOIN users u ON d.user_id = u.id
   WHERE u.email = $1;"
  |> based.new_query
  |> based.with_values([based.string(string.lowercase(email.val))])
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
        , is_automatic_withdrawal
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

pub fn upsert_definition(
  definition: Definition,
  email: Email,
  db: DB,
) -> Result(Nil, Error) {
  use sql <- result.try(case get_one(definition.id, db) {
    Ok(_found) -> {
      Ok(
        "
        UPDATE definitions
        SET description = $1
           ,amount = $2
           ,frequency = $3
           ,start_date = $4
           ,end_date = $5
           ,is_automatic_withdrawal = $6
        WHERE identifier = $7 AND user_id = (SELECT u.id FROM users u WHERE u.email = $8);
        ",
      )
    }
    Error(NotFoundError) -> {
      Ok(
        "INSERT INTO definitions(description, amount, frequency, start_date, end_date, is_automatic_withdrawal, identifier, user_id)
         SELECT $1,$2, $3, $4, $5, $6, $7, u.id
         FROM users u
         WHERE email = $8;",
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
    based.bool(definition.is_automatic_withdrawal),
    based.string(id.unwrap(definition.id)),
    based.string(string.lowercase(email.val)),
  ])
  |> based.execute(db)
  |> result.map_error(DbError)
  |> result.replace(Nil)
}

fn definition_decoder(dyn: Dynamic) -> Result(Definition, DecodeErrors) {
  dynamic.decode7(
    fn(a, b, c, d, e, f, g) { Definition(a, b, c, d, e, f, g == 1) },
    dynamic.element(0, id.decoder),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.float),
    dynamic.element(3, definition.frequency_decoder),
    dynamic.element(4, decoders.day_decoder),
    dynamic.element(5, dynamic.optional(decoders.day_decoder)),
    dynamic.element(6, dynamic.int),
  )(dyn)
}
