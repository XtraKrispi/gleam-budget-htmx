import utils/password.{type Password}

pub type Email {
  Email(val: String)
}

pub type User {
  User(email: Email, password_hash: Password, name: String)
}
