import antigone
import gleam/bit_array
import gleam/dynamic.{type DecodeErrors, type Dynamic}

pub opaque type Password {
  Password(pass: String)
}

pub fn create_password(pass: String) -> Password {
  pass |> hash_password |> Password
}

pub fn unwrap_password(pass: Password) {
  pass.pass
}

pub fn password_decoder(dyn: Dynamic) -> Result(Password, DecodeErrors) {
  dynamic.decode1(Password, dynamic.string)(dyn)
}

fn hash_password(password: String) -> String {
  let bits = bit_array.from_string(password)

  antigone.hash(antigone.hasher(), bits)
}

pub fn validate_password(to_verify: String, hashed_password: Password) -> Bool {
  antigone.verify(
    bit_array.from_string(to_verify),
    unwrap_password(hashed_password),
  )
}
