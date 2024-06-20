import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre_hx.{CssSelector, Event, OuterHTML} as hx
import types/definition.{type Definition, Definition}
import types/id
import utils/formatters

pub fn full_page() {
  html.div(
    [
      attribute.class("px-20 py-10"),
      hx.hyper_script(
        "on showDefinitionsModal call definition_modal.showModal() end
         on hideDefinitionsModal from body call definition_modal.close() end",
      ),
    ],
    [
      html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
        html.h2([], [html.text("Definitions")]),
        html.button(
          [
            attribute.class("btn btn-primary"),
            hx.get("/admin/definitions/new"),
            hx.target(CssSelector("#definition_modal")),
            hx.swap(OuterHTML, None),
          ],
          [html.text("New")],
        ),
      ]),
      html.main(
        [
          attribute.id("definitions"),
          hx.get("/admin/definitions"),
          hx.trigger([Event("load", [])]),
          hx.swap(OuterHTML, None),
        ],
        [html.text("Loading")],
      ),
      definition_modal_shell(),
    ],
  )
}

pub fn definitions_table(definitions: List(Definition)) {
  html.main(
    [
      attribute.id("definitions"),
      hx.get("/admin/definitions"),
      hx.swap(OuterHTML, None),
      hx.trigger([Event("reload", [hx.From(hx.CssSelector("body"))])]),
    ],
    [
      case list.is_empty(definitions) {
        True -> html.p([], [html.text("No definitions found")])
        False ->
          html.table([attribute.class("table table-zebra")], [
            html.thead([], [
              html.tr([], [
                html.th([], [html.text("Description")]),
                html.th([], [html.text("Amount")]),
                html.th([], [html.text("Frequency")]),
                html.th([], [html.text("Start Date")]),
                html.th([], [html.text("End Date")]),
              ]),
            ]),
            html.tbody([], list.map(definitions, render_definition_row)),
          ])
      },
    ],
  )
}

fn render_definition_row(definition: Definition) {
  html.tr(
    [
      attribute.class("hover cursor-pointer"),
      hx.get("/admin/definitions/" <> id.unwrap(definition.id)),
      hx.target(CssSelector("#definition_modal")),
      hx.swap(OuterHTML, None),
    ],
    [
      html.th([], [html.text(definition.description)]),
      html.td([], [
        html.text(
          "$" <> formatters.format_float(definition.amount, 2, Some(",")),
        ),
      ]),
      html.td([], [html.text(formatters.format_frequency(definition.frequency))]),
      html.td([], [html.text(formatters.format_date(definition.start_date))]),
      html.td([], [
        definition.end_date
        |> option.map(formatters.format_date)
        |> option.unwrap("--")
        |> html.text,
      ]),
    ],
  )
}

fn definition_modal_shell() {
  html.dialog([attribute.class("modal"), attribute.id("definition_modal")], [])
}

pub fn render_definition_modal(definition: Definition) {
  let Definition(id, desc, amt, freq, start, end) = definition
  html.dialog([attribute.class("modal"), attribute.id("definition_modal")], [
    html.div([attribute.class("modal-box")], [
      html.form([attribute.method("dialog")], [
        html.button(
          [
            attribute.class(
              "btn btn-sm btn-circle btn-ghost absolute right-2 top-2",
            ),
          ],
          [html.text("✕")],
        ),
      ]),
      html.h3([attribute.class("font-bold text-lg")], [html.text("Hello!")]),
      html.p([attribute.class("py-4")], [
        html.text("Press ESC key or click on ✕ button to close"),
      ]),
      html.form(
        [
          attribute.class("flex flex-col space-y-2"),
          hx.post("/admin/definitions/" <> id.unwrap(id)),
        ],
        [
          html.input([
            attribute.type_("hidden"),
            attribute.name("id"),
            attribute.value(id.unwrap(id)),
          ]),
          html.label([attribute.class("form-control w-full max-w-xs")], [
            html.input([
              attribute.class("input input-bordered w-full max-w-xs"),
              attribute.value(desc),
              attribute.placeholder("Description"),
              attribute.name("description"),
              attribute.required(True),
            ]),
          ]),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(amt |> formatters.format_float(2, None)),
            attribute.placeholder("Amount"),
            attribute.name("amount"),
            attribute.required(True),
          ]),
          html.select(
            [
              attribute.class("select select-bordered w-full max-w-xs"),
              attribute.name("frequency"),
            ],
            definition.frequencies()
              |> list.map(fn(f) {
                html.option(
                  [
                    attribute.selected(f == freq),
                    attribute.value(definition.encode_frequency(f)),
                  ],
                  formatters.format_frequency(f),
                )
              }),
          ),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(start |> formatters.format_date),
            attribute.name("start_date"),
            attribute.type_("date"),
            attribute.required(True),
          ]),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(
              end |> option.map(formatters.format_date) |> option.unwrap(""),
            ),
            attribute.name("end_date"),
            attribute.type_("date"),
          ]),
          html.div([attribute.class("modal-action")], [
            html.button(
              [attribute.class("btn btn-primary"), attribute.type_("submit")],
              [html.text("Save")],
            ),
          ]),
        ],
      ),
    ]),
  ])
}
