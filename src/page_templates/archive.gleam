import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre_hx.{Event} as hx
import types/archived_item.{type ArchivedItem}
import utils/formatters

pub fn full_page() {
  html.div([attribute.class("px-20 py-10")], [
    html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
      html.h2([], [html.text("Archive")]),
    ]),
    html.main(
      [
        hx.swap(hx.OuterHTML, None),
        hx.get("/archive"),
        hx.trigger([Event("load", [])]),
      ],
      [html.text("Loading")],
    ),
  ])
}

pub fn items(items: List(ArchivedItem)) {
  html.main([attribute.class("prose flex flex-col space-y-4")], case
    list.is_empty(items)
  {
    False -> items |> list.map(render_item)

    True -> [html.h3([], [html.text("No items found...")])]
  })
}

pub fn render_item(item: ArchivedItem) {
  html.div([attribute.class("card w-96 bg-base-100 shadow-xl")], [
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
          case item.action {
            archived_item.Paid ->
              html.div([attribute.class("badge badge-primary")], [
                html.text("Paid"),
              ])
            archived_item.Skipped ->
              html.div([attribute.class("badge badge-accent")], [
                html.text("Skipped"),
              ])
          },
        ]),
      ]),
    ]),
  ])
}
