import app/handlers/archive.{archive, archive_page}
import app/handlers/common.{to_response}
import app/handlers/definitions.{definition, definitions_page} as _definitions_handlers
import app/handlers/home.{home_page}
import app/handlers/login.{login_page}
import app/handlers/register.{register}
import app/web.{type Context}
import based.{type DB}
import birl
import birl/duration
import db/sessions as sessions_db
import db/users as users_db
import gleam/http
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import htmx/request
import lustre/element/html
import types/archived_item.{Paid, Skipped}
import types/error.{type Error, SessionError}
import types/id
import types/session.{SessionId}
import types/user.{type User, User}
import utils/list as my_list
import wisp.{type Request, type Response}

fn validate_cookie(val: String, db: DB) -> Result(User, Error) {
  let session_id = SessionId(val)
  case users_db.get_user_for_session(session_id, db) {
    Ok(#(user, expiration_time)) -> {
      case birl.compare(expiration_time, birl.now()) {
        order.Gt | order.Eq -> {
          let result = case
            duration.compare(
              birl.difference(expiration_time, birl.now()),
              duration.minutes(10),
            )
          {
            order.Lt | order.Eq ->
              sessions_db.update_session(
                session_id,
                birl.now() |> birl.add(duration.minutes(20)),
                db,
              )
            _ -> Ok(Nil)
          }
          case result {
            Ok(_) -> Ok(user)
            Error(e) -> Error(e)
          }
        }
        _ -> Error(SessionError)
      }
    }
    Error(e) -> {
      Error(e)
    }
  }
}

fn requires_auth(
  req: Request,
  db: DB,
  handler: fn(User) -> Response,
) -> Response {
  {
    use cookie_val <- result.try(wisp.get_cookie(
      req,
      "AUTH_COOKIE",
      wisp.Signed,
    ))

    use user <- result.try(
      validate_cookie(cookie_val, db) |> result.replace_error(Nil),
    )

    Ok(
      handler(user)
      |> wisp.set_cookie(req, "AUTH_COOKIE", cookie_val, wisp.Signed, 1200),
    )
  }
  |> result.unwrap(case request.is_htmx(req) {
    True -> wisp.no_content() |> wisp.set_header("HX-Location", "/login")
    False -> wisp.redirect("/login")
  })
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> requires_auth(req, ctx.db, home_page(req, _, ctx.db))
    ["login"] -> login_page(req, ctx.db)
    ["admin", "definitions"] ->
      requires_auth(req, ctx.db, definitions_page(req, _, ctx.db))
    ["admin", "definitions", "new"] ->
      requires_auth(req, ctx.db, definition(req, _, ctx.db, None))
    ["admin", "definitions", id] ->
      requires_auth(req, ctx.db, definition(req, _, ctx.db, Some(id.wrap(id))))
    ["archive"] -> requires_auth(req, ctx.db, archive_page(req, _, ctx.db))
    ["archive", "skip"] ->
      requires_auth(req, ctx.db, archive(req, _, ctx.db, Skipped))
    ["archive", "pay"] ->
      requires_auth(req, ctx.db, archive(req, _, ctx.db, Paid))
    ["toast", "clear"] -> html.text("") |> my_list.singleton |> to_response(200)
    ["register"] -> register(req, ctx.db)
    ["session"] ->
      requires_auth(req, ctx.db, fn(_user) { destroy_session(req, ctx.db) })
    _ -> wisp.not_found()
  }
}

fn destroy_session(req, db) {
  use <- wisp.require_method(req, http.Delete)

  case wisp.get_cookie(req, "AUTH_COOKIE", wisp.Signed) {
    Ok(val) -> {
      let _ = sessions_db.destroy_session(SessionId(val), db)
      wisp.no_content()
      |> wisp.set_cookie(req, "AUTH_COOKIE", val, wisp.Signed, -100)
    }
    Error(_) -> wisp.no_content()
  }
  |> wisp.set_header("HX-Redirect", "/")
}
