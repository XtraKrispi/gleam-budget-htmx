import app/handlers/common.{error_toast, to_response}
import app/layout
import based.{type DB}
import birl
import birl/duration
import db/archive as archive_db
import db/definitions as definition_db
import db/users as users_db
import gleam/http.{Get, Post}
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result
import htmx/request
import logic/items
import page_templates/home
import types/scratch.{type Scratch, Scratch}
import types/user.{type User}
import utils/decoders
import utils/list as my_list
import wisp.{type Request}

pub fn home_page(req: Request, user: User, db: DB) {
  let default_scratch =
    Scratch(birl.get_day(birl.add(birl.now(), duration.days(21))), 0.0, 0.0)
  case req.method {
    Get -> {
      case !request.is_boosted(req) && request.is_htmx(req) {
        True -> {
          let scratch = case users_db.get_scratch(user.email, db) {
            Ok(Some(s)) -> s
            _ -> default_scratch
          }
          home_content(user, scratch, db)
        }
        False ->
          home.full_page()
          |> layout.with_layout(user)
          |> to_response(200)
      }
    }
    Post -> {
      use form_data <- wisp.require_form(req)
      let scratch =
        {
          use end_date <- result.try(
            form_data.values
            |> list.find_map(fn(kvp) {
              case kvp.0 == "end_date" {
                True -> decoders.parse_day(kvp.1)
                False -> Error(Nil)
              }
            }),
          )

          use amount_in_bank <- result.try(
            form_data.values
            |> list.find_map(fn(kvp) {
              case kvp {
                #("amount_in_bank", "") -> Ok(0.0)
                #("amount_in_bank", val) -> decoders.parse_float(val)
                _ -> Error(Nil)
              }
            }),
          )
          use amount_left_over <- result.try(
            form_data.values
            |> list.find_map(fn(kvp) {
              case kvp {
                #("amount_left_over", "") -> Ok(0.0)
                #("amount_left_over", val) -> decoders.parse_float(val)
                _ -> Error(Nil)
              }
            }),
          )

          Ok(Scratch(end_date, amount_in_bank, amount_left_over))
        }
        |> result.unwrap(default_scratch)
      let _ = users_db.save_user_scratch(user.email, scratch, db)
      home_content(user, scratch, db)
    }
    _ -> wisp.bad_request()
  }
}

pub fn home_content(user: User, scratch: Scratch, db: DB) {
  let definitions = definition_db.get_all(user.email, db)
  let archive = archive_db.get_all(user.email, db)

  case definitions, archive {
    Ok(defs), Ok(a) -> {
      let items =
        items.get_items(defs, scratch.end_date)
        |> list.filter(fn(item) {
          !list.any(a, fn(arch) {
            item.definition_id == arch.item_definition_id
            && item.date == arch.date
          })
        })
      home.content(items, scratch)
      |> my_list.singleton
      |> to_response(200)
    }
    e1, e2 -> {
      io.debug(e1)
      io.debug(e2)
      error_toast(
        "There was an issue fetching items, please refresh and try again.",
      )
    }
  }
}
