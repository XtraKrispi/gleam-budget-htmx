import app/handlers/common.{to_response}
import app/layout
import based.{type DB}
import birl
import birl/duration
import db/sessions as sessions_db
import db/users as users_db
import gleam/http
import gleam/list
import gleam/result
import lustre/element/html
import page_templates/login as login_page
import types/session.{Session, SessionId}
import utils/list as my_list
import utils/password
import wisp.{type Request, type Response}

pub fn login_page(req: Request, db: DB) -> Response {
  case req.method {
    http.Get ->
      login_page.full_page()
      |> my_list.singleton
      |> layout.with_page_shell
      |> my_list.singleton
      |> to_response(200)
    http.Post -> {
      // TODO: Login email is case sensitive
      use form_data <- wisp.require_form(req)
      let is_validated = {
        use e <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "email" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          }),
        )

        use p <- result.try(
          form_data.values
          |> list.find_map(fn(kvp) {
            case kvp.0 {
              "password" -> Ok(kvp.1)
              _ -> Error(Nil)
            }
          }),
        )

        use user <- result.try(
          users_db.get_by_email(e, db) |> result.replace_error(Nil),
        )

        Ok(#(user, password.validate_password(p, user.password_hash)))
      }

      let error_response =
        layout.add_toast(
          html.span([], [
            html.text("There was a problem logging in, please try again."),
          ]),
          layout.Error,
        )
        |> my_list.singleton
        |> to_response(200)
        |> wisp.set_header("HX-Reswap", "none")
      case is_validated {
        Ok(#(user, True)) -> {
          // Create a session
          let expiration_time = birl.now() |> birl.add(duration.minutes(20))
          case sessions_db.create_session(user.email, expiration_time, db) {
            Ok(Session(SessionId(session_id), _)) -> {
              wisp.no_content()
              |> wisp.set_cookie(
                req,
                "AUTH_COOKIE",
                session_id,
                wisp.Signed,
                1200,
              )
              |> wisp.set_header("HX-Redirect", "/")
            }
            Error(_) -> {
              error_response
            }
          }
        }
        // Log in
        _ -> error_response
      }
    }
    _ -> wisp.not_found()
  }
}
