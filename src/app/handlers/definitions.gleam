import app/handlers/common.{error_toast, to_response}
import app/layout
import based.{type DB}
import birl
import db/definitions as definition_db
import gleam/http.{Get, Post}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import htmx/request
import page_templates/definitions
import types/definition.{type Definition, Definition, OneTime}
import types/id.{type Id}
import types/user.{type User}
import utils/decoders
import utils/list as my_list
import wisp.{type Request, type Response}

pub fn definitions_page(req: Request, user: User, database: DB) -> Response {
  use <- wisp.require_method(req, Get)
  case request.is_htmx(req) && !request.is_boosted(req) {
    False -> {
      definitions.full_page()
      |> layout.with_layout(user)
      |> to_response(200)
    }
    True -> {
      case definition_db.get_all(user.email, database) {
        Ok(defs) -> {
          defs
          |> definitions.definitions_table
          |> my_list.singleton
          |> to_response(200)
        }
        Error(_e) -> {
          error_toast(
            "There was an issue fetching definitions, please refresh the page and try again.",
          )
        }
      }
    }
  }
}

pub fn definition(
  req: Request,
  user: User,
  db: DB,
  id: Option(Id(Definition)),
) -> Response {
  case req.method {
    Get -> {
      let definition = case id {
        Some(i) -> {
          definition_db.get_one(i, db)
        }
        None ->
          Ok(Definition(
            id.new_id(),
            "",
            0.0,
            OneTime,
            birl.now()
              |> birl.get_day,
            None,
            False,
          ))
      }

      case definition {
        Ok(def) ->
          definitions.render_definition_modal(def)
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Trigger-After-Settle", "showDefinitionsModal")
        Error(_) ->
          error_toast(
            "There was an issue fetching the definition.  Please try again.",
          )
      }
    }
    Post -> {
      use form <- wisp.require_form(req)
      case hydrate_definition(form) {
        Ok(definition) ->
          case definition_db.upsert_definition(definition, user.email, db) {
            Ok(_) ->
              wisp.no_content()
              |> wisp.set_header("HX-Trigger", "hideDefinitionsModal, reload")
            Error(_) ->
              error_toast(
                "There was an issue saving the definition, please try again.",
              )
          }
        Error(_) -> error_toast("Bad request, please check your formatting.")
      }
    }
    _ -> error_toast("Something went wrong, please try again.")
  }
}

fn hydrate_definition(form: wisp.FormData) {
  use id <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "id" {
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

  use frequency <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "frequency" {
        True -> definition.parse_frequency(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use start_date <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "start_date" {
        True -> decoders.parse_day(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use end_date <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "end_date", kvp.1 {
        True, "" -> Ok(None)
        True, d -> decoders.parse_day(d) |> result.map(Some)
        False, _ -> Error(Nil)
      }
    }),
  )

  let is_automatic_withdrawal =
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "is_automatic_withdrawal", kvp.1 {
        True, "on" -> Ok(True)
        _, _ -> Error(Nil)
      }
    })
    |> result.unwrap(False)

  Ok(Definition(
    id,
    description,
    amount,
    frequency,
    start_date,
    end_date,
    is_automatic_withdrawal,
  ))
}
