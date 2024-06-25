import antigone
import gleam/bit_array

pub fn hash_password(password: String) -> String {
  let bits = bit_array.from_string(password)

  antigone.hash(antigone.hasher(), bits)
}

pub fn validate_password(password: String, hashed_password: String) -> Bool {
  antigone.verify(bit_array.from_string(password), hashed_password)
}
