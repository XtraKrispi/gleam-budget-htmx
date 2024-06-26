import based.{type DB}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/result
import gleam/string
import types/archived_item.{
  type ArchiveAction, type ArchivedItem, ArchivedItem, Paid, Skipped,
}
import types/error.{type Error, DbError}
import types/id
import types/user.{type Email}
import utils/decoders
import utils/formatters

pub fn get_all(email: Email, db: DB) -> Result(List(ArchivedItem), Error) {
  "SELECT identifier
        , item_definition_identifier
        , description
        , amount
        , date
        , action_date
        , action
   FROM archive a
   JOIN users u ON a.user_id = u.id
   WHERE u.email = $1"
  |> based.new_query
  |> based.with_values([based.string(string.lowercase(email.val))])
  |> based.all(db, archive_decoder)
  |> result.map(fn(r) { r.rows })
  |> result.map_error(DbError)
}

pub fn insert(item: ArchivedItem, email: Email, db: DB) -> Result(Nil, Error) {
  "INSERT INTO archive(identifier
        , item_definition_identifier
        , description
        , amount
        , date
        , action_date
        , action
        , user_id)
   SELECT $1, $2, $3, $4, $5, $6, $7, u.id
   FROM users u
   WHERE u.email = $8;"
  |> based.new_query
  |> based.with_values([
    based.string(id.unwrap(item.id)),
    based.string(id.unwrap(item.item_definition_id)),
    based.string(item.description),
    based.float(item.amount),
    based.string(formatters.format_date(item.date)),
    based.string(formatters.format_date(item.action_date)),
    based.string(encode_archive_action(item.action)),
    based.string(string.lowercase(email.val)),
  ])
  |> based.execute(db)
  |> result.map_error(DbError)
  |> result.replace(Nil)
}

fn archive_decoder(dyn: Dynamic) -> Result(ArchivedItem, DecodeErrors) {
  dynamic.decode7(
    ArchivedItem,
    dynamic.element(0, id.decoder),
    dynamic.element(1, id.decoder),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.float),
    dynamic.element(4, decoders.day_decoder),
    dynamic.element(5, decoders.day_decoder),
    dynamic.element(6, archived_item.archive_action_decoder),
  )(dyn)
}

fn encode_archive_action(action: ArchiveAction) {
  case action {
    Paid -> "paid"
    Skipped -> "skipped"
  }
}
