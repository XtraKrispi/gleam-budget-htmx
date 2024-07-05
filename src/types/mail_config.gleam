import gleam/option.{type Option}

pub type Name {
  Name(name: String)
}

pub type EmailAddress {
  EmailAddress(email_address: String)
}

pub type MailRecipient {
  MailRecipient(email_address: EmailAddress, name: Option(Name))
}

pub type Relay {
  Relay(relay: String)
}

pub type Port {
  Port(port: Int)
}

pub type Username {
  Username(username: String)
}

pub type Password {
  Password(password: String)
}

pub type Hostname {
  Hostname(hostname: String)
}

pub type MailConfig {
  MailConfig(
    from: MailRecipient,
    relay: Relay,
    port: Port,
    username: Username,
    password: Password,
    hostname: Hostname,
  )
}
