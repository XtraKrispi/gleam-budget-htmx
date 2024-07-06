import antigone
import based.{type Value}
import gleam/bit_array
import wisp

pub opaque type Token(a) {
  Token(token: String)
}

pub type Hashed

pub type ClearText

pub fn mk_token(str: String) -> Token(ClearText) {
  Token(str)
}

pub fn to_based(token: Token(Hashed)) -> Value {
  based.string(token.token)
}

pub fn to_string(token: Token(ClearText)) -> String {
  token.token
}

pub fn hash_token(token: Token(ClearText)) -> Token(Hashed) {
  let bits = bit_array.from_string(token.token)

  let hashed = antigone.hash(antigone.hasher(), bits)
  Token(hashed)
}

pub fn generate_token() -> #(Token(ClearText), Token(Hashed)) {
  let token_str = wisp.random_string(64)
  let bits = bit_array.from_string(token_str)

  let hashed = antigone.hash(antigone.hasher(), bits)
  #(Token(token_str), Token(hashed))
}
