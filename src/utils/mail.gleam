import gleam/dict
import gleam/list
import gleam/option
import gleam/string
import gleam/string_builder
import types/mail_config.{type MailConfig, type MailRecipient}

pub type Email =
  #(String, List(String), String)

pub type IfAvailable {
  Always
  Never
  IfAvailable
}

pub type Option(a) {
  Ssl(Bool)
  Tls(IfAvailable)
  Port(Int)
  Hostname(String)
  Username(String)
  Password(String)
  Relay(String)
  Auth(IfAvailable)
  TlsOptions(a)
  SslOptions(a)
}

@external(erlang, "gen_smtp_client", "send_blocking")
fn send(email: Email, options: List(Option(a))) -> Result(a, b)

@external(erlang, "tls_certificate_check", "options")
fn tls_cert_check(relay: a) -> b

@external(erlang, "mimemail", "encode")
fn encode_html(a: a) -> String

fn format_recipient(recipient: MailRecipient) -> String {
  string_builder.new()
  |> string_builder.append(
    recipient.name |> option.map(fn(n) { n.name <> " " }) |> option.unwrap(""),
  )
  |> string_builder.append("<")
  |> string_builder.append(recipient.email_address.email_address)
  |> string_builder.append(">")
  |> string_builder.to_string
}

fn get_email_tuple(
  mail_config: MailConfig,
  to: List(MailRecipient),
  full_body: String,
) -> Email {
  #(
    mail_config.from.email_address.email_address,
    to |> list.map(fn(r) { r.email_address.email_address }),
    full_body,
  )
}

pub fn send_mail(
  config: MailConfig,
  to: List(MailRecipient),
  subject: String,
  body: String,
) {
  let email =
    encode_html(#(
      "text",
      "html",
      [
        #("From", format_recipient(config.from)),
        #("Subject", subject),
        #(
          "To",
          to
            |> list.map(format_recipient)
            |> string.join(","),
        ),
      ],
      dict.new() |> dict.insert("disposition", "inline"),
      body,
    ))
  send(get_email_tuple(config, to, email), [
    Relay(config.relay.relay),
    Port(config.port.port),
    Username(config.username.username),
    Password(config.password.password),
    Hostname(config.hostname.hostname),
    Auth(Always),
    Tls(Always),
    TlsOptions(tls_cert_check(config.relay.relay)),
  ])
}
