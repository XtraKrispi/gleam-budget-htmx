import app/layout
import app/web.{type Context}
import based.{type DB}
import birl
import birl/duration
import db/archive as archive_db
import db/definitions as definition_db
import gleam/http.{Get, Post}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import htmx/request
import logic/items
import lustre/element.{type Element}
import page_templates/archive as archive_page
import page_templates/definitions
import page_templates/home
import types/archived_item.{ArchivedItem, Paid, Skipped}
import types/definition.{type Definition, Definition, OneTime}
import types/id.{type Id}
import types/item.{type Item, Item}
import utils/decoders
import wisp.{type Request, type Response}

fn to_response(elem: Element(t), status_code: Int) -> Response {
  elem
  |> element.to_document_string_builder
  |> wisp.html_response(status_code)
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> home_page()
    ["items"] -> items(req, ctx.db)
    ["admin", "definitions"] -> definitions_page(req, ctx.db)
    ["admin", "definitions", "new"] -> definition(req, ctx.db, None)
    ["admin", "definitions", id] -> definition(req, ctx.db, Some(id.wrap(id)))
    ["archive"] -> archive_page()
    ["archive", "skip"] -> archive(req, ctx.db, Skipped)
    ["archive", "pay"] -> archive(req, ctx.db, Paid)
    _ -> wisp.not_found()
  }
}

fn home_page() -> Response {
  home.full_page()
  |> layout.with_layout
  |> to_response(200)
}

fn definitions_page(req: Request, database: DB) -> Response {
  use <- wisp.require_method(req, Get)
  case request.is_htmx(req) && !request.is_boosted(req) {
    False -> {
      definitions.full_page()
      |> layout.with_layout
      |> to_response(200)
    }
    True -> {
      case definition_db.get_all(database) {
        Ok(defs) -> {
          defs
          |> definitions.definitions_table
          |> to_response(200)
        }
        Error(_e) -> {
          wisp.internal_server_error()
        }
      }
    }
  }
}

fn archive_page() -> Response {
  archive_page.full_page()
  |> layout.with_layout
  |> to_response(200)
}

pub fn items(req: Request, db: DB) -> Response {
  let query_strings = wisp.get_query(req)
  let end_date =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "end_date" })
    |> result.try(fn(qs) { decoders.parse_day(qs.1) })
    |> result.unwrap(birl.get_day(birl.add(birl.now(), duration.days(21))))

  let definitions = definition_db.get_all(db)
  let archive = archive_db.get_all(db)

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
      home.items(items)
      |> to_response(200)
    }
    _, _ -> wisp.internal_server_error()
  }
}

fn definition(req: Request, db: DB, id: Option(Id(Definition))) -> Response {
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
          ))
      }

      case definition {
        Ok(def) ->
          definitions.render_definition_modal(def)
          |> to_response(200)
          |> wisp.set_header("HX-Trigger-After-Settle", "showDefinitionsModal")
        Error(_) ->
          todo as "Need to return something indicating something went wrong... a toast?"
      }
    }
    Post -> {
      use form <- wisp.require_form(req)
      case hydrate_definition(form) {
        Ok(definition) ->
          case definition_db.upsert_definition(definition, db) {
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

pub fn archive(req, db, action) {
  use <- wisp.require_method(req, Post)
  use form_data <- wisp.require_form(req)
  case hydrate_item(form_data) {
    Ok(item) -> {
      case item |> convert_to_archive(action) |> archive_db.insert(db) {
        Ok(_) -> wisp.no_content()
        Error(err) -> {
          io.debug(err)
          wisp.internal_server_error()
        }
      }
    }
    Error(err) -> {
      io.debug(err)
      wisp.internal_server_error()
    }
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

  Ok(Definition(id, description, amount, frequency, start_date, end_date))
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

  Ok(Item(id, description, amount, date))
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
