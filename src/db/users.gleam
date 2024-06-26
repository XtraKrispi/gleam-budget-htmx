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

pub fn insert_user(user: User, db: DB) {
  "INSERT INTO users(email, name, password_hash, password_reset_token)
    VALUES($1, $2, $3, null)"
  |> based.new_query
  |> based.with_values([
    based.string(user.email),
    based.string(user.name),
    based.string(user.unwrap_password(user.password_hash)),
  ])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(Nil)
}

fn user_decoder(dyn: Dynamic) -> Result(User, DecodeErrors) {
  dynamic.decode3(
    User,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, user.password_decoder),
    dynamic.element(2, dynamic.string),
  )(dyn)
}
