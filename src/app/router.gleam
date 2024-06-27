import app/handlers/common.{error_toast, to_response}
import app/handlers/definitions.{definition, definitions_page} as _definitions_handlers
import app/layout
import app/web.{type Context}
import based.{type DB}
import birl
import birl/duration
import db/archive as archive_db
import db/definitions as definition_db
import db/sessions as sessions_db
import db/users as users_db
import gleam/http.{Get, Post}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regex
import gleam/result
import gleam/string
import htmx/request
import logic/items
import lustre/element/html
import page_templates/archive as archive_page
import page_templates/home
import page_templates/login as login_page
import types/archived_item.{ArchivedItem, Paid, Skipped}
import types/error.{type Error, SessionError}
import types/forms
import types/id
import types/item.{type Item, Item}
import types/session.{Session, SessionId}
import types/user.{type User, Email, User}
import utils/decoders
import utils/list as my_list
import utils/password
import wisp.{type Request, type Response}

fn validate_cookie(val: String, db: DB) -> Result(User, Error) {
  let session_id = SessionId(val)
  io.debug(session_id)
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
      io.debug(e)
      Error(e)
    }
  }
}

pub fn requires_auth(
  req: Request,
  db: DB,
  handler: fn(Request, User) -> Response,
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
      handler(req, user)
      |> wisp.set_cookie(req, "AUTH_COOKIE", cookie_val, wisp.Signed, 1200),
    )
  }
  |> result.unwrap(wisp.redirect("/login"))
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] ->
      // TODO: Clean this up
      requires_auth(req, ctx.db, fn(req, user) { home_page(req, user, ctx.db) })
    ["login"] -> login_page(req, ctx.db)
    ["admin", "definitions"] ->
      requires_auth(req, ctx.db, fn(req, user) {
        definitions_page(req, user, ctx.db)
      })
    ["admin", "definitions", "new"] ->
      requires_auth(req, ctx.db, fn(req, user) {
        definition(req, user, ctx.db, None)
      })
    ["admin", "definitions", id] ->
      requires_auth(req, ctx.db, fn(req, user) {
        definition(req, user, ctx.db, Some(id.wrap(id)))
      })
    ["archive"] ->
      requires_auth(req, ctx.db, fn(req, user) {
        archive_page(req, user, ctx.db)
      })
    ["archive", "skip"] ->
      requires_auth(req, ctx.db, fn(req, user) {
        archive(req, user.email, ctx.db, Skipped)
      })
    ["archive", "pay"] ->
      requires_auth(req, ctx.db, fn(req, user) {
        archive(req, user.email, ctx.db, Paid)
      })
    ["toast", "clear"] -> html.text("") |> my_list.singleton |> to_response(200)
    ["register"] -> register(req, ctx.db)
    ["session"] ->
      requires_auth(req, ctx.db, fn(req, _user) { destroy_session(req, ctx.db) })
    _ -> wisp.not_found()
  }
}

fn home_page(req, user, db) -> Response {
  let query_strings = wisp.get_query(req)
  let end_date =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "end_date" })
    |> result.try(fn(qs) { decoders.parse_day(qs.1) })
    |> result.unwrap(birl.get_day(birl.add(birl.now(), duration.days(21))))

  let amount_in_bank =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "amount_in_bank" })
    |> result.try(fn(qs) { decoders.parse_float(qs.1) })

  let amount_left_over =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "amount_left_over" })
    |> result.try(fn(qs) { decoders.parse_float(qs.1) })

  case request.is_htmx(req) && !request.is_boosted(req) {
    True -> home_content(user, end_date, amount_in_bank, amount_left_over, db)
    False ->
      home.full_page(end_date, amount_in_bank, amount_left_over)
      |> layout.with_layout(user)
      |> to_response(200)
      |> wisp.set_header("NEEDS_AUTH", "Hello")
  }
}

fn archive_page(req: Request, user: User, db: DB) -> Response {
  case request.is_htmx(req) && !request.is_boosted(req) {
    True -> {
      let archive_items = archive_db.get_all(user.email, db)
      case archive_items {
        Ok(items) ->
          archive_page.items(items)
          |> my_list.singleton
          |> to_response(200)
        Error(_) ->
          layout.add_toast(
            html.span([], [
              html.text(
                "There was a problem retrieving archive items. Please refresh and try again.",
              ),
            ]),
            layout.Error,
          )
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Reswap", "none")
      }
    }
    False ->
      archive_page.full_page()
      |> layout.with_layout(user)
      |> to_response(200)
  }
}

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

pub fn home_content(
  user: User,
  end_date,
  amount_in_bank: Result(Float, Nil),
  amount_left_over: Result(Float, Nil),
  db: DB,
) -> Response {
  let definitions = definition_db.get_all(user.email, db)
  let archive = archive_db.get_all(user.email, db)

  case definitions, archive {
    Ok(defs), Ok(a) -> {
      let items =
        items.get_items(defs, end_date)
        |> list.filter(fn(item) {
          !list.any(a, fn(arch) {
            item.definition_id == arch.item_definition_id
            && item.date == arch.date
          })
        })
      home.content(items, end_date, amount_in_bank, amount_left_over)
      |> my_list.singleton
      |> to_response(200)
    }
    _, _ ->
      error_toast(
        "There was an issue fetching items, please refresh and try again.",
      )
  }
}

pub fn archive(req, user, db, action) {
  use <- wisp.require_method(req, Post)
  use form_data <- wisp.require_form(req)
  case hydrate_item(form_data) {
    Ok(item) -> {
      case item |> convert_to_archive(action) |> archive_db.insert(user, db) {
        Ok(_) -> wisp.no_content() |> wisp.set_header("HX-Trigger", "reload")
        Error(_err) ->
          error_toast("Could not move to the archive, please try again.")
      }
    }
    Error(_err) -> error_toast("Bad request, please check your formatting.")
  }
}

fn hydrate_item(form: wisp.FormData) {
  use id <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "definition_id" {
        True -> Ok(id.wrap(kvp.1))
        False -> Error(Nil)
      }
    }),
  )

  use description <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "description" {
        True -> Ok(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use amount <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "amount" {
        True -> decoders.parse_float(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use date <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "date" {
        True -> decoders.parse_day(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use is_automatic_withdrawal <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "is_automatic_withdrawal" {
        True -> Ok(kvp.1 == "true")
        False -> Error(Nil)
      }
    }),
  )
  Ok(Item(id, description, amount, date, is_automatic_withdrawal))
}

fn convert_to_archive(item: Item, action) {
  ArchivedItem(
    id.new_id(),
    item.definition_id,
    item.description,
    item.amount,
    item.date,
    birl.now() |> birl.get_day,
    action,
  )
}

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
            forms.InputWithValidation(v, validate_email(v, db))
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
                    Email(f.email.value),
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

fn validate_email(email: String, db: DB) {
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
