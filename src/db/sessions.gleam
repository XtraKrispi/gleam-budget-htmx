import based.{type DB}
import birl.{type Time}
import gleam/result
import gleam/string
import gluid
import types/error.{type Error}
import types/session.{type Session, type SessionId, Session, SessionId}
import types/user.{type Email}

pub fn create_session(
  email: Email,
  expiration_time: Time,
  db: DB,
) -> Result(Session, Error) {
  let session_id = gluid.guidv4()
  "INSERT INTO sessions (session_id, user_id, expiration_time)
   SELECT $1, u.id, $2 
   FROM users u
   WHERE email = $3;"
  |> based.new_query
  |> based.with_values([
    based.string(session_id),
    based.string(birl.to_iso8601(expiration_time)),
    based.string(string.lowercase(email.val)),
  ])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(Session(SessionId(session_id), expiration_time))
}

pub fn update_session(session_id: SessionId, new_expiration_time: Time, db: DB) {
  "UPDATE sessions
     SET expiration_time = $1
     WHERE session_id = $2;"
  |> based.new_query
  |> based.with_values([
    based.string(birl.to_iso8601(new_expiration_time)),
    based.string(session_id.id),
  ])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(Nil)
}

pub fn destroy_session(session_id: SessionId, db: DB) -> Result(Nil, Error) {
  "DELETE FROM sessions WHERE session_id = $1;"
  |> based.new_query
  |> based.with_values([based.string(session_id.id)])
  |> based.execute(db)
  |> result.replace(Nil)
  |> result.map_error(error.DbError)
}
