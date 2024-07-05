import antigone
import gleam/bit_array
import wisp

pub type Token(a) {
  Token(token: String)
}

pub type Hashed

pub type ClearText

pub fn generate_token() -> #(Token(ClearText), Token(Hashed)) {
  let token_str = wisp.random_string(64)
  let bits = bit_array.from_string(token_str)

  let hashed = antigone.hash(antigone.hasher(), bits)
  #(Token(token_str), Token(hashed))
}
