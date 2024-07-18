import birl.{type Time}
import gleam/list
import gleam/order
import types/user.{type User}
import utils/reset_token.{type ClearText, type Hashed, type Token}

pub type Error {
  TokenNotFound(Token(ClearText))
  TokenExpired
}

pub fn get_user(
  token: Token(ClearText),
  all_users: List(#(User, Time, Token(Hashed))),
  current_time: Time,
) -> Result(User, Error) {
  case list.filter(all_users, user_matches(token, _)) {
    [] -> Error(TokenNotFound(token))
    matches ->
      case list.find(matches, expiry_matches(_, current_time)) {
        Ok(#(user, _, _)) -> Ok(user)
        Error(_) -> Error(TokenExpired)
      }
  }
}

fn user_matches(
  token: Token(ClearText),
  user: #(User, Time, Token(Hashed)),
) -> Bool {
  let #(_, _, hashed) = user
  reset_token.verify_token(token, hashed)
}

fn expiry_matches(t: #(User, Time, Token(Hashed)), current_time: Time) -> Bool {
  let #(_, expiry, _) = t
  case birl.compare(current_time, expiry) {
    order.Lt | order.Eq -> True
    _ -> False
  }
}
