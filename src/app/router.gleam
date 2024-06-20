import app/layout
import app/web.{type Context}
import based.{type DB}
import birl
import db/definitions as db
import gleam/http.{Get, Post}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import htmx/request
import lustre/element.{type Element}
import lustre/element/html
import page_templates/definitions
import types/definition.{type Definition, Definition, OneTime}

import types/id.{type Id}
import wisp.{type Request, type Response}

fn to_response(elem: Element(t), status_code: Int) -> Response {
  elem
  |> element.to_document_string_builder
  |> wisp.html_response(status_code)
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> home_page() |> to_response(200)

    ["admin", "definitions"] -> definitions(req, ctx.db)
    ["admin", "definitions", "new"] -> definition(req, ctx.db, None)
    ["admin", "definitions", id] -> definition(req, ctx.db, Some(id.wrap(id)))
    _ -> wisp.not_found()
  }
}

fn home_page() -> Element(t) {
  html.div([], [html.text("Did I do it?")])
  |> layout.with_layout
}

fn definitions(req: Request, database: DB) -> Response {
  use <- wisp.require_method(req, Get)
  case request.is_htmx(req) {
    False -> {
      definitions.full_page()
      |> layout.with_layout
      |> to_response(200)
    }
    True -> {
      case db.get_all(database) {
        Ok(defs) -> {
          defs
          |> definitions.definitions_table
          |> to_response(200)
        }
        Error(e) -> {
          wisp.internal_server_error()
        }
      }
    }
  }
}

fn definition(req: Request, db: DB, id: Option(Id(Definition))) -> Response {
  case req.method {
    Get -> {
      let definition = case id {
        Some(i) -> {
          db.get_one(i, db)
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
          ))
      }

      case definition {
        Ok(def) ->
          definitions.render_definition_modal(def)
          |> to_response(200)
          |> wisp.set_header("HX-Trigger-After-Settle", "showDefinitionsModal")
        Error(_) -> todo
      }
    }
    Post -> {
      use form <- wisp.require_form(req)
      case hydrate_definition(form) {
        Ok(definition) ->
          case db.upsert_definition(definition, db) {
            Ok(_) ->
              wisp.no_content()
              |> wisp.set_header("HX-Trigger", "hideDefinitionsModal, reload")
            Error(_) -> wisp.internal_server_error()
          }
        Error(_) -> wisp.internal_server_error()
      }
    }
    _ -> wisp.not_found()
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
        True -> definition.parse_float(kvp.1)
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
        True -> definition.parse_day(kvp.1)
        False -> Error(Nil)
      }
    }),
  )

  use end_date <- result.try(
    form.values
    |> list.find_map(fn(kvp) {
      case kvp.0 == "end_date", kvp.1 {
        True, "" -> Ok(None)
        True, d -> definition.parse_day(d) |> result.map(Some)
        False, _ -> Error(Nil)
      }
    }),
  )

  Ok(Definition(id, description, amount, frequency, start_date, end_date))
}
