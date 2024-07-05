import app/handlers/common.{to_response}
import app/layout
import based.{type DB}
import birl
import birl/duration
import db/users as users_db
import gleam/http.{Get, Post}
import gleam/list
import gleam/option.{None}
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
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
      reset_password.landing_page()
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
          let _results = {
            use _ <- result.try(users_db.insert_reset_token(
              email,
              t,
              expiry,
              db,
            ))
            use _ <- result.try(mail.send_mail(
              config,
              [MailRecipient(mail_config.EmailAddress(email.val), None)],
              "Budget - Reset Password",
              element.to_string(reset_password_email(url)),
            ))

            Ok(Nil)
          }

          layout.add_toast(
            html.span([], [
              html.text(
                "If you have an account with Budget, please check your email for a password reset link.",
              ),
            ]),
            layout.Success,
          )
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Reswap", "none")
        }

        Error(_) ->
          layout.add_toast(
            html.span([], [
              html.text(
                "There was an issue reading the email address, please try again.",
              ),
            ]),
            layout.Error,
          )
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Reswap", "none")
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

fn reset_password_email(url: String) -> Element(a) {
  html.div([], [
    html.h1([], [html.text("Budget - Reset Password")]),
    html.p([], [
      html.text("Please click the link below to reset your password."),
    ]),
    html.p([], [html.text("The link will expire in 10 minutes.")]),
    html.p([], [html.a([attribute.href(url)], [html.text("Click here")])]),
  ])
}
