import birl

pub type SessionId {
  SessionId(id: String)
}

pub type Session {
  Session(id: SessionId, expiration_time: birl.Time)
}
