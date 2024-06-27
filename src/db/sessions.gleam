import based.{type DB}
import types/error.{type Error}
import types/session.{type SessionId}
import types/user.{type User}

pub fn create_session(email: String, db: DB) -> Result(SessionId, Error) {
  todo
}

pub fn destroy_session(session_id: SessionId, db: DB) -> Result(Nil, Error) {
  todo
}

pub fn get_user_for_session(
  session_id: SessionId,
  db: DB,
) -> Result(User, Error) {
  todo
}
