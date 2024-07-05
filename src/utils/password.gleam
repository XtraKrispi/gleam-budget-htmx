import gleam/dynamic.{type DecodeErrors, type Dynamic}
import utils/hash

pub opaque type Password {
  Password(pass: String)
}

pub fn create_password(pass: String) -> Password {
  pass |> hash.hash |> Password
}

pub fn unwrap_password(pass: Password) {
  pass.pass
}

pub fn password_decoder(dyn: Dynamic) -> Result(Password, DecodeErrors) {
  dynamic.decode1(Password, dynamic.string)(dyn)
}

pub fn validate_password(to_verify: String, hashed_password: Password) -> Bool {
  hash.verify(to_verify, unwrap_password(hashed_password))
}
