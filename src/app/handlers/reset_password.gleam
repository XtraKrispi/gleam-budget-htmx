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
import logic/password_reset
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import page_templates/reset_password
import types/mail_config.{type MailConfig, MailRecipient}
import types/user.{type Email, Email}
import utils/list as my_list
import utils/mail
import utils/password
import utils/reset_token.{type ClearText, type Token}
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
        #("token", token) -> Ok(reset_token.mk_token(token))
        _ -> Error(Nil)
      }
    })
  case m_token {
    Ok(token) -> token_page(req, db, token)
    Error(_) -> initial_page(req, db, config, base_url)
  }
}

fn initial_page(req: Request, db: DB, config: MailConfig, base_url: String) {
  case req.method {
    Get -> {
      reset_password.landing_page()
      |> my_list.singleton
      |> layout.with_page_shell
      |> my_list.singleton
      |> to_response(200)
    }
    Post -> {
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
          let #(clear_text, t) = reset_token.generate_token()
          let url =
            base_url
            <> "/reset_password?token="
            <> reset_token.to_string(clear_text)
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
    _ -> wisp.bad_request()
  }
}

fn token_page(req: Request, db: DB, token: Token(ClearText)) {
  case req.method {
    Get -> {
      // Display reset password page with password form (after verifying token)
      case users_db.get_users_for_reset_password(db) {
        Ok(all_users) -> {
          case password_reset.get_user(token, all_users, birl.now()) {
            Error(_err) -> {
              reset_password.error_page()
              |> my_list.singleton
              |> layout.with_page_shell
              |> my_list.singleton
              |> to_response(200)
            }
            Ok(_user) -> {
              // We're good, let them change their password
              reset_password.token_page(token)
              |> my_list.singleton
              |> layout.with_page_shell
              |> my_list.singleton
              |> to_response(200)
            }
          }
        }

        Error(_e) -> {
          // Generic error page
          reset_password.error_page()
          |> my_list.singleton
          |> layout.with_page_shell
          |> my_list.singleton
          |> to_response(200)
        }
      }
    }
    Post -> {
      use form_data <- wisp.require_form(req)
      let password = {
        use pass <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "password" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          }),
        )
        use pass_confirm <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "password_confirmation" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          }),
        )

        case pass == pass_confirm {
          True -> Ok(pass)
          False -> Error(Nil)
        }
      }

      // Password validation
      case password {
        Error(_) ->
          layout.add_toast(
            html.span([], [html.text("Something went wrong, please try again.")]),
            layout.Error,
          )
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Reswap", "none")
        Ok(pass) -> {
          // Update password, after verifying password and token
          // revalidating the token ... is this correct?
          case users_db.get_users_for_reset_password(db) {
            Ok(users) ->
              case password_reset.get_user(token, users, birl.now()) {
                Error(_err) -> {
                  layout.add_toast(
                    html.span([], [
                      html.text("Something went wrong, please try again."),
                    ]),
                    layout.Error,
                  )
                  |> my_list.singleton
                  |> to_response(200)
                  |> wisp.set_header("HX-Reswap", "none")
                }
                Ok(user) -> {
                  // Token's good, reset their password AND remove all tokens for the user
                  let new_password = password.create_password(pass)
                  case
                    users_db.update_user_password(user.email, new_password, db),
                    users_db.remove_all_user_tokens(user.email, db)
                  {
                    Ok(_), Ok(_) ->
                      layout.add_toast(
                        html.span([], [
                          html.text(
                            "You have successfully reset your password, you may now log in.",
                          ),
                        ]),
                        layout.Success,
                      )
                      |> my_list.singleton
                      |> to_response(200)
                      |> wisp.set_header("HX-Redirect", "/login")
                    _, _ ->
                      layout.add_toast(
                        html.span([], [
                          html.text("Something went wrong, please try again."),
                        ]),
                        layout.Error,
                      )
                      |> my_list.singleton
                      |> to_response(200)
                      |> wisp.set_header("HX-Reswap", "none")
                  }
                }
              }
            Error(_) ->
              layout.add_toast(
                html.span([], [
                  html.text("Something went wrong, please try again."),
                ]),
                layout.Error,
              )
              |> my_list.singleton
              |> to_response(200)
              |> wisp.set_header("HX-Reswap", "none")
          }
        }
      }
    }
    _ -> wisp.bad_request()
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
