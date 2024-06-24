import birl.{type Day}
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre_hx.{Event} as hx
import types/item.{type Item}
import utils/formatters

pub fn full_page(end_date) {
  html.div([attribute.class("px-20 py-10")], [
    html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
      html.h2([], [html.text("Home")]),
    ]),
    html.div(
      [
        hx.trigger([Event("load", [])]),
        hx.get("/?end_date=" <> formatters.format_date(end_date)),
        hx.swap(hx.OuterHTML, None),
        attribute.id("home_content"),
      ],
      [
        html.main([], [html.text("Loading")]),
        html.aside([], [html.text("Loading")]),
      ],
    ),
  ])
}

pub fn content(items: List(Item), end_date: Day) {
  html.div(
    [
      attribute.class("flex space-x-12 w-screen"),
      attribute.id("home_content"),
      hx.trigger([Event("reload from:body", [])]),
      hx.get("/"),
      hx.swap(hx.OuterHTML, None),
    ],
    [items_section(items), scratch_area(items, end_date)],
  )
}

pub fn items_section(items: List(Item)) {
  html.main(
    [attribute.class("flex flex-col space-y-4 gerow")],
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

pub fn scratch_area(items: List(Item), end_date: Day) {
  let total = items |> list.fold(0.0, fn(a, b) { a +. b.amount })
  html.aside([attribute.class("flex flex-col space-y-4 min-w-[320px]")], [
    html.form([], [
      html.input([
        attribute.class("input input-bordered w-full max-w-xs"),
        attribute.value(end_date |> formatters.format_date),
        attribute.name("end_date"),
        attribute.type_("date"),
        hx.get("/"),
        hx.target(hx.CssSelector("#home_content")),
        hx.trigger([Event("change", [])]),
        hx.swap(hx.OuterHTML, None),
        hx.push_url(True),
      ]),
    ]),
    html.div([attribute.class("prose")], [
      html.form([attribute.class("flex flex-col space-y-4")], [
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount in account"),
          attribute.name("in_bank"),
        ]),
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount left over"),
          attribute.name("left_over"),
        ]),
      ]),
      html.div([], [
        html.h3([attribute.class("flex justify-between")], [
          html.span([], [html.text("Total Owing:")]),
          html.span([], [
            html.text("$" <> formatters.format_float(total, 2, Some(","))),
          ]),
        ]),
        html.h3([attribute.class("flex justify-between")], [
          html.span([], [html.text("Total Outstanding:")]),
          html.span([], [html.text("$" <> "0.00")]),
        ]),
      ]),
    ]),
  ])
}
