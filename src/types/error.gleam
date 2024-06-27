import based.{type BasedError}

pub type Error {
  DbError(error: BasedError)
  NotFoundError
  SessionError
}
