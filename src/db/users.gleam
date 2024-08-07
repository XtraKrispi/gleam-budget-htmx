import based.{type DB}
import birl.{type Time}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import types/error
import types/scratch.{type Scratch, Scratch}
import types/session
import types/user.{type Email, type User, Email, User}
import utils/decoders
import utils/formatters
import utils/password.{type Password}
import utils/reset_token.{type Hashed, type Token}

pub fn get_all(db: DB) {
  "SELECT email, password_hash, name
   FROM users"
  |> based.new_query
  |> based.all(db, user_decoder)
  |> result.map(fn(x) { x.rows })
  |> result.map_error(error.DbError)
}

pub fn get_by_email(email: Email, db: DB) {
  "SELECT email, password_hash, name
   FROM users
   WHERE email = $1;"
  |> based.new_query
  |> based.with_values([based.string(string.lowercase(email.val))])
  |> based.one(db, user_decoder)
  |> result.map_error(error.DbError)
}

pub fn insert_user(user: User, db: DB) {
  "INSERT INTO users(email, name, password_hash)
    VALUES($1, $2, $3)"
  |> based.new_query
  |> based.with_values([
    based.string(string.lowercase(user.email.val)),
    based.string(user.name),
    based.string(password.unwrap_password(user.password_hash)),
  ])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(Nil)
}

pub fn update_user_password(email: Email, password: Password, db: DB) {
  "UPDATE users 
  SET password_hash = $1
  WHERE email = $2;"
  |> based.new_query
  |> based.with_values([
    based.string(password.unwrap_password(password)),
    based.string(email.val),
  ])
  |> based.execute(db)
  |> result.replace(Nil)
  |> result.replace_error(error.DbError)
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

pub fn get_scratch(email: Email, db: DB) -> Result(Option(Scratch), error.Error) {
  "SELECT s.end_date, s.amount_in_bank, s.amount_left_over
   FROM scratch s
   JOIN users u ON s.user_id = u.id
   WHERE u.email = $1"
  |> based.new_query
  |> based.with_values([based.string(string.lowercase(email.val))])
  |> based.all(db, scratch_decoder)
  |> result.map(fn(s) {
    case s.rows {
      [] -> None
      [x, ..] -> Some(x)
    }
  })
  |> result.map_error(error.DbError)
}

pub fn save_user_scratch(email: Email, scratch: Scratch, db: DB) {
  "INSERT INTO scratch(user_id, end_date, amount_in_bank, amount_left_over)
    SELECT u.id, $1, $2, $3
    FROM users u
    WHERE u.email = $4
   ON CONFLICT(user_id) DO
    UPDATE
    SET end_date = excluded.end_date, amount_in_bank =  excluded.amount_in_bank, amount_left_over = excluded.amount_left_over;"
  |> based.new_query
  |> based.with_values([
    based.string(formatters.format_date(scratch.end_date)),
    based.float(scratch.amount_in_bank),
    based.float(scratch.amount_left_over),
    based.string(string.lowercase(email.val)),
  ])
  |> based.execute(db)
  |> result.replace(Nil)
  |> result.map_error(error.DbError)
}

pub fn insert_reset_token(
  email: Email,
  token: Token(Hashed),
  token_expiry: Time,
  db: DB,
) -> Result(Nil, error.Error) {
  let results =
    "INSERT INTO password_reset_tokens(user_id, token, token_expiry)
     SELECT u.id, $1, $2
     FROM users u
     WHERE u.email = $3
     RETURNING user_id;"
    |> based.new_query
    |> based.with_values([
      reset_token.to_based(token),
      based.string(birl.to_iso8601(token_expiry)),
      based.string(string.lowercase(email.val)),
    ])
    |> based.all(db, dynamic.element(0, dynamic.string))
    |> result.map(fn(r) { r.count })
  case results {
    Ok(0) -> Error(error.NotFoundError)
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(error.DbError(e))
  }
}

pub fn get_users_for_reset_password(db: DB) {
  "SELECT u.email, u.password_hash, u.name, prt.token_expiry, prt.token
   FROM password_reset_tokens prt
   JOIN users u ON prt.user_id = u.id;"
  |> based.new_query
  |> based.all(
    db,
    dynamic.decode3(
      fn(a, b, c) { #(a, b, c) },
      user_decoder,
      dynamic.element(3, decoders.time_decoder),
      dynamic.element(4, reset_token.token_decoder),
    ),
  )
  |> result.map(fn(r) { r.rows })
  |> result.map_error(error.DbError)
}

pub fn remove_all_user_tokens(email: Email, db: DB) {
  "DELETE FROM password_reset_tokens
  WHERE user_id IN 
    (SELECT id 
     FROM users 
     WHERE email = $1);"
  |> based.new_query
  |> based.with_values([based.string(string.lowercase(email.val))])
  |> based.execute(db)
  |> result.replace(Nil)
  |> result.replace_error(error.DbError)
}

fn user_decoder(dyn: Dynamic) -> Result(User, DecodeErrors) {
  dynamic.decode3(
    User,
    dynamic.element(0, dynamic.decode1(Email, dynamic.string)),
    dynamic.element(1, password.password_decoder),
    dynamic.element(2, dynamic.string),
  )(dyn)
}

fn scratch_decoder(dyn: Dynamic) -> Result(Scratch, DecodeErrors) {
  dynamic.decode3(
    Scratch,
    dynamic.element(0, decoders.day_decoder),
    dynamic.element(1, dynamic.float),
    dynamic.element(2, dynamic.float),
  )(dyn)
}
