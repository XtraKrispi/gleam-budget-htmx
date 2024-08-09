import gleam/float
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre_hx.{Event} as hx
import types/item.{type Item}
import types/scratch.{type Scratch}
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
        attribute.id("home_content"),
      ],
      [
        html.main([], [html.text("Loading")]),
        html.aside([], [html.text("Loading")]),
      ],
    ),
  ])
}

pub fn content(items: List(Item), scratch: Scratch) {
  html.div(
    [
      attribute.class("flex space-x-12 w-screen"),
      attribute.id("home_content"),
      hx.trigger([Event("reload from:body", [])]),
      hx.get("/"),
      hx.swap(hx.OuterHTML, None),
    ],
    [items_section(items), scratch_area(items, scratch)],
  )
}

pub fn items_section(items: List(Item)) {
  html.main([attribute.class("flex flex-col space-y-4 gerow")], case
    list.is_empty(items)
  {
    True -> [html.div([], [html.text("No items to display!")])]
    False -> items |> list.map(render_item)
  })
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
          html.span(
            [
              attribute.class("cursor-pointer"),
              hx.hyper_script(
                "on click writeText('"
                <> formatters.format_float(item.amount, 2, None)
                <> "') on navigator.clipboard",
              ),
            ],
            [
              html.text(
                "$" <> formatters.format_float(item.amount, 2, Some(",")),
              ),
            ],
          ),
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

pub fn scratch_area(items: List(Item), scratch: Scratch) {
  let total = items |> list.fold(0.0, fn(a, b) { a +. b.amount })
  let amount_in_bank_calc = scratch.amount_in_bank
  let amount_left_over_calc = scratch.amount_left_over
  let total_outstanding =
    float.max(0.0, { total +. amount_left_over_calc } -. amount_in_bank_calc)
  html.aside([attribute.class("prose flex flex-col space-y-4 min-w-[320px]")], [
    html.form(
      [
        attribute.class("flex flex-col space-y-4"),
        hx.post("/"),
        hx.target(hx.CssSelector("#home_content")),
        hx.swap(hx.OuterHTML, None),
        hx.push_url(True),
      ],
      [
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.value(scratch.end_date |> formatters.format_date),
          attribute.name("end_date"),
          attribute.type_("date"),
          attribute.attribute("hx-include", "closest form"),
        ]),
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount in account"),
          attribute.name("amount_in_bank"),
          attribute.value(case scratch.amount_in_bank {
            0.0 -> ""
            _ -> formatters.format_float(scratch.amount_in_bank, 2, None)
          }),
        ]),
        html.input([
          attribute.class("input input-bordered w-full max-w-xs"),
          attribute.placeholder("Amount to be left over"),
          attribute.name("amount_left_over"),
          attribute.attribute("hx-include", "closest form"),
          attribute.value(case scratch.amount_left_over {
            0.0 -> ""
            _ -> formatters.format_float(scratch.amount_left_over, 2, None)
          }),
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
