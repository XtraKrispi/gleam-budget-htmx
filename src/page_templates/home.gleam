import birl.{type Day}
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element/html
import lustre_hx.{Event} as hx
import types/item.{type Item}
import utils/formatters

pub fn full_page(
  end_date,
  amount_in_bank: Result(Float, Nil),
  amount_left_over: Result(Float, Nil),
) {
  let amt_in_bank_query = case amount_in_bank {
    Ok(f) -> [#("amount_in_bank", formatters.format_float(f, 2, None))]
    _ -> []
  }
  let amt_in_left_over_query = case amount_left_over {
    Ok(f) -> [#("amount_left_over", formatters.format_float(f, 2, None))]
    _ -> []
  }
  let query_string =
    [
      #("end_date", formatters.format_date(end_date)),
      ..{ list.concat([amt_in_bank_query, amt_in_left_over_query]) }
    ]
    |> list.map(fn(x) { string.join([x.0, x.1], "=") })
    |> string.join("&")

  html.div([attribute.class("px-20 py-10")], [
    html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
      html.h2([], [html.text("Home")]),
    ]),
    html.div(
      [
        hx.trigger([Event("load", [])]),
        hx.get("/?" <> query_string),
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

pub fn content(
  items: List(Item),
  end_date: Day,
  amount_in_bank: Result(Float, Nil),
  amount_left_over: Result(Float, Nil),
) {
  html.div(
    [
      attribute.class("flex space-x-12 w-screen"),
      attribute.id("home_content"),
      hx.trigger([Event("reload from:body", [])]),
      hx.get("/"),
      hx.swap(hx.OuterHTML, None),
    ],
    [
      items_section(items),
      scratch_area(items, end_date, amount_in_bank, amount_left_over),
    ],
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
        html.div([attribute.class("flex justify-between items-center")], [
          html.div([], [
            case item.is_automatic_withdrawal {
              True ->
                html.div([attribute.class("badge badge-primary")], [
                  html.text("Automatic"),
                ])
              False -> html.text("")
            },
          ]),
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
      ]),
    ],
  )
}

pub fn scratch_area(
  items: List(Item),
  end_date: Day,
  amount_in_bank: Result(Float, Nil),
  amount_left_over: Result(Float, Nil),
) {
  let total = items |> list.fold(0.0, fn(a, b) { a +. b.amount })
  let amount_in_bank_calc = amount_in_bank |> result.unwrap(0.0)
  let amount_left_over_calc = amount_left_over |> result.unwrap(0.0)
  let total_outstanding =
    float.max(0.0, { total +. amount_left_over_calc } -. amount_in_bank_calc)
  html.aside([attribute.class("prose flex flex-col space-y-4 min-w-[320px]")], [
    html.form(
      [
        attribute.class("flex flex-col space-y-4"),
        hx.get("/"),
        hx.target(hx.CssSelector("#home_content")),
        hx.swap(hx.OuterHTML, None),
        hx.push_url(True),
      ],
      [
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.value(end_date |> formatters.format_date),
          attribute.name("end_date"),
          attribute.type_("date"),
          attribute.attribute("hx-include", "closest form"),
        ]),
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount in account"),
          attribute.name("amount_in_bank"),
          attribute.value(
            amount_in_bank
            |> result.map(formatters.format_float(_, 2, None))
            |> result.unwrap(""),
          ),
        ]),
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount to be left over"),
          attribute.name("amount_left_over"),
          attribute.attribute("hx-include", "closest form"),
          attribute.value(
            amount_left_over
            |> result.map(formatters.format_float(_, 2, None))
            |> result.unwrap(""),
          ),
        ]),
        html.button(
          [attribute.class("btn btn-primary"), attribute.type_("submit")],
          [html.text("Recalculate")],
        ),
      ],
    ),
    html.div([], [
      html.h3([attribute.class("flex justify-between")], [
        html.span([], [html.text("Total Owing:")]),
        html.span([], [
          html.text("$" <> formatters.format_float(total, 2, Some(","))),
        ]),
      ]),
      html.h3([attribute.class("flex justify-between")], [
        html.span([], [html.text("Total Outstanding:")]),
        html.span([], [
          html.text(
            "$" <> formatters.format_float(total_outstanding, 2, Some(",")),
          ),
        ]),
      ]),
    ]),
  ])
}
