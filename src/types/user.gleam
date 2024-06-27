import gleam/dynamic.{type DecodeErrors, type Dynamic}
import utils/password.{type Password}

pub type User {
  User(email: String, password_hash: Password, name: String)
}
