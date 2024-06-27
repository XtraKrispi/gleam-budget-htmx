import app/layout
import gleam/list
import gleam/string_builder
import lustre/element.{type Element}
import lustre/element/html
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
