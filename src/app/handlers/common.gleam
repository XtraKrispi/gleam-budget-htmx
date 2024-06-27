import app/layout
import gleam/list
import gleam/result
import gleam/string_builder
import lustre/element.{type Element}
import lustre/element/html
import types/id
import types/item.{Item}
import utils/decoders
import utils/list as my_list
import wisp.{type Response}

pub fn to_response(elems: List(Element(t)), status_code: Int) -> Response {
  elems
  |> list.map(element.to_document_string_builder)
  |> string_builder.concat
  |> wisp.html_response(status_code)
}

pub fn error_toast(msg) {
  layout.add_toast(html.span([], [html.text(msg)]), layout.Error)
  |> my_list.singleton
  |> to_response(200)
  |> wisp.set_header("HX-Reswap", "none")
}

pub fn hydrate_item(form: wisp.FormData) {
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
