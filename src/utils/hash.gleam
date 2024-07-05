import antigone
import gleam/bit_array

pub fn hash(str: String) -> String {
  let bits = bit_array.from_string(str)

  antigone.hash(antigone.hasher(), bits)
}

pub fn verify(str: String, hashed: String) {
  antigone.verify(bit_array.from_string(str), hashed)
}
