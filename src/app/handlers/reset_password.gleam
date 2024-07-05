import app/handlers/common.{to_response}
import app/layout
import based.{type DB}
import birl
import birl/duration
import db/users as users_db
import gleam/http.{Get, Post}
import gleam/list
import gleam/option.{None}
import lustre/element
import lustre/element/html
import page_templates/reset_password
import types/mail_config.{type MailConfig, MailRecipient}
import types/user.{type Email, Email}
import utils/list as my_list
import utils/mail
import utils/reset_token.{Token}
import wisp.{type Request, type Response}

pub fn reset_password(
  req: Request,
  db: DB,
  config: MailConfig,
  base_url: String,
) -> Response {
  let m_token =
    wisp.get_query(req)
    |> list.find_map(fn(kvp) {
      case kvp {
        #("token", token) -> Ok(token)
        _ -> Error(Nil)
      }
    })
  case req.method, m_token {
    Get, Error(_) -> {
      reset_password.full_page()
      |> my_list.singleton
      |> layout.with_page_shell
      |> my_list.singleton
      |> to_response(200)
    }
    Post, Error(_) -> {
      use form_data <- wisp.require_form(req)
      case
        form_data.values
        |> list.find_map(fn(kvp) {
          case kvp.0 {
            "email" -> Ok(Email(kvp.1))
            _ -> Error(Nil)
          }
        })
      {
        Ok(email) -> {
          // Generate token and send email
          let #(Token(clear_text), t) = reset_token.generate_token()
          let url = base_url <> "/reset_password?token=" <> clear_text
          let expiry = birl.now() |> birl.add(duration.minutes(10))

          case Ok(Nil) {
            //users_db.insert_reset_token(email, t, expiry, db) {
            Ok(_) -> {
              let _ =
                mail.send_mail(
                  config,
                  [MailRecipient(mail_config.EmailAddress(email.val), None)],
                  "Test",
                  element.to_string(html.div([], [html.text("This is a test")])),
                )
              wisp.no_content()
            }
            Error(_) -> {
              wisp.internal_server_error()
            }
          }
        }
        Error(_) -> wisp.bad_request()
      }
    }
    Get, Ok(token) -> {
      // Display reset password page with password form (after verifying token)
      todo
    }
    Post, Ok(token) -> {
      // Update password, after verifying password and token
      todo
    }
    _, _ -> wisp.bad_request()
  }
}
