import gleam/dynamic.{type DecodeErrors, type Dynamic}
import utils/password

pub type User {
  User(email: String, password_hash: Password, name: String)
}

pub opaque type Password {
  Password(pass: String)
}

pub fn hash_password(pass: String) -> Password {
  pass |> password.hash_password |> Password
}

pub fn unwrap_password(pass: Password) {
  pass.pass
}

pub fn password_decoder(dyn: Dynamic) -> Result(Password, DecodeErrors) {
  dynamic.decode1(Password, dynamic.string)(dyn)
}
