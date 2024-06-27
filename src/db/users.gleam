import based.{type DB}
import birl.{type Time}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/result
import types/error
import types/session
import types/user.{type User, Email, User}
import utils/decoders
import utils/password

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
    based.string(user.email.val),
    based.string(user.name),
    based.string(password.unwrap_password(user.password_hash)),
  ])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(Nil)
}

pub fn get_user_for_session(
  session_id: session.SessionId,
  db: DB,
) -> Result(#(User, Time), error.Error) {
  "SELECT u.email
        , u.name
        , u.password_hash
        , s.expiration_time
   FROM users u 
   JOIN sessions s ON u.id = s.user_id
   WHERE s.session_id = $1;"
  |> based.new_query
  |> based.with_values([based.string(session_id.id)])
  |> based.one(
    db,
    dynamic.decode2(
      fn(a, b) { #(a, b) },
      user_decoder,
      dynamic.element(3, decoders.time_decoder),
    ),
  )
  |> result.map_error(error.DbError)
}

fn user_decoder(dyn: Dynamic) -> Result(User, DecodeErrors) {
  dynamic.decode3(
    User,
    dynamic.element(0, dynamic.decode1(Email, dynamic.string)),
    dynamic.element(1, password.password_decoder),
    dynamic.element(2, dynamic.string),
  )(dyn)
}
