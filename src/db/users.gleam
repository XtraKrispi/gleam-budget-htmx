import based.{type DB}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/result
import types/error
import types/user.{type User, User}

pub fn get_all(db: DB) {
  "SELECT email, password_hash, name
   FROM users"
  |> based.new_query
  |> based.all(db, user_decoder)
  |> result.map(fn(x) { x.rows })
  |> result.map_error(error.DbError)
}

pub fn get_by_email(email: String, db: DB) {
  "SELECT email, password_hash, name
   FROM users
   WHERE email = $1;"
  |> based.new_query
  |> based.with_values([based.string(email)])
  |> based.one(db, user_decoder)
  |> result.map_error(error.DbError)
}

fn user_decoder(dyn: Dynamic) -> Result(User, DecodeErrors) {
  dynamic.decode3(
    User,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, user.password_decoder),
    dynamic.element(2, dynamic.string),
  )(dyn)
}
