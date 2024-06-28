import app/handlers/common.{to_response}
import app/layout
import based.{type DB}
import db/users as users_db
import gleam/http
import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import lustre/element/html
import page_templates/login as login_page
import types/forms
import types/user.{type Email, Email, User}
import utils/list as my_list
import utils/password
import wisp.{type Request}

pub fn register(req: Request, db: DB) {
  case req.method {
    http.Get -> {
      login_page.registration_form(forms.default_registration_form())
      |> my_list.singleton
      |> to_response(200)
      |> wisp.set_header("HX-Trigger", "showRegistrationModal")
    }
    http.Post -> {
      use form_data <- wisp.require_form(req)

      let form = {
        use email <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "email" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          })
          |> result.map(fn(v) {
            forms.InputWithValidation(v, validate_email(Email(v), db))
          }),
        )

        use name <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "name" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          }),
        )

        use password <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "password" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          })
          |> result.map(fn(v) {
            forms.InputWithValidation(v, validate_password(v))
          }),
        )

        use password_confirm <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "password_confirm" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          })
          |> result.map(fn(p) {
            forms.InputWithValidation(p, case password.value == p {
              True -> []
              False -> ["Passwords don't match"]
            })
          }),
        )

        Ok(forms.RegistrationForm(email, name, password, password_confirm))
      }

      case form {
        Ok(f) ->
          case is_form_valid(f) {
            True -> {
              // Write the user info
              case
                users_db.insert_user(
                  User(
                    Email(string.lowercase(f.email.value)),
                    password.create_password(f.password.value),
                    f.name,
                  ),
                  db,
                )
              {
                Ok(_) ->
                  layout.add_toast(
                    html.span([], [
                      html.text("You've been signed up! Please log in below"),
                    ]),
                    layout.Success,
                  )
                  |> my_list.singleton
                  |> to_response(200)
                  |> wisp.set_header("HX-Trigger", "hideRegistrationModal")

                Error(_) -> {
                  [
                    layout.add_toast(
                      html.span([], [
                        html.text(
                          "There was an issue signing up, please try again.",
                        ),
                      ]),
                      layout.Error,
                    ),
                    login_page.registration_form(f),
                  ]
                  |> to_response(200)
                }
              }
            }
            False ->
              login_page.registration_form(f)
              |> my_list.singleton
              |> to_response(200)
          }
        Error(_) -> wisp.no_content() |> wisp.set_header("HX-Reswap", "none")
      }
    }
    _ -> wisp.not_found()
  }
}

fn is_form_valid(form: forms.RegistrationForm) {
  list.is_empty(form.email.errors)
  && list.is_empty(form.password.errors)
  && list.is_empty(form.password_confirm.errors)
}

fn validate_email(email: Email, db: DB) {
  case users_db.get_by_email(email, db) {
    Ok(_) -> ["Email is already taken"]
    Error(_) -> []
  }
}

fn validate_password(pass: String) {
  let assert Ok(reg) =
    regex.from_string(
      "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$",
    )
  case regex.check(reg, pass) {
    True -> []
    False -> ["Password does not meet the requirements"]
  }
}
