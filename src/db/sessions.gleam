import based.{type DB}
import gleam/result
import gluid
import types/error.{type Error}
import types/session.{type SessionId, SessionId}

pub fn create_session(email: String, db: DB) -> Result(SessionId, Error) {
  let session_id = gluid.guidv4()
  "INSERT INTO sessions (session_id, user_id)
   SELECT $1, u.id 
   FROM users u
   WHERE email = $2;"
  |> based.new_query
  |> based.with_values([based.string(session_id), based.string(email)])
  |> based.execute(db)
  |> result.map_error(error.DbError)
  |> result.replace(SessionId(session_id))
}

pub fn destroy_session(session_id: SessionId, db: DB) -> Result(Nil, Error) {
  "DELETE FROM sessions WHERE session_id = $1;"
  |> based.new_query
  |> based.with_values([based.string(session_id.id)])
  |> based.execute(db)
  |> result.replace(Nil)
  |> result.map_error(error.DbError)
}
