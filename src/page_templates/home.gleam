import birl.{type Day}
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre_hx.{Event} as hx
import types/item.{type Item}
import utils/formatters

pub fn full_page() {
  html.div([attribute.class("px-20 py-10")], [
    html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
      html.h2([], [html.text("Home")]),
    ]),
    html.div(
      [
        hx.trigger([Event("load", [])]),
        hx.get("/"),
        hx.swap(hx.OuterHTML, None),
      ],
      [
        html.main([], [html.text("Loading")]),
        html.aside([], [html.text("Loading")]),
      ],
    ),
  ])
}

pub fn content(items: List(Item)) {
  html.div([], [
    items_section(items),
    scratch_area(items, birl.now() |> birl.get_day),
  ])
}

pub fn items_section(items: List(Item)) {
  html.main(
    [
      attribute.class("flex flex-col space-y-4"),
      hx.trigger([Event("reload from:body", [])]),
      hx.get("/"),
      hx.swap(hx.OuterHTML, None),
    ],
    items |> list.map(render_item),
  )
}

fn render_item(item: Item) {
  html.div(
    [
      attribute.class("card w-96 bg-base-100 shadow-xl"),
      attribute.attribute("hx-vals", item.item_to_json(item)),
    ],
    [
      html.div([attribute.class("card-body")], [
        html.h2([attribute.class("card-title flex justify-between")], [
          html.span([], [html.text(item.description)]),
          html.span([], [
            html.text("$" <> formatters.format_float(item.amount, 2, Some(","))),
          ]),
        ]),
        html.p([], [html.text(formatters.format_date(item.date))]),
        html.div([attribute.class("card-actions justify-end")], [
          html.button([attribute.class("btn"), hx.post("/archive/skip")], [
            html.text("Skip"),
          ]),
          html.button(
            [attribute.class("btn btn-primary"), hx.post("/archive/pay")],
            [html.text("Pay")],
          ),
        ]),
      ]),
    ],
  )
}

pub fn scratch_area(_items: List(Item), _end_date: Day) {
  html.aside([], [])
}
