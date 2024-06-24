import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element/html
import lustre/element/svg
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
          [
            html.text("New"),
            html.svg(
              [
                attribute.class("h-6 w-6"),
                attribute.attribute("fill", "none"),
                attribute.attribute("viewBox", "0 0 24 24"),
                attribute.attribute("stroke-width", "1.5"),
                attribute.attribute("stroke", "currentColor"),
              ],
              [
                svg.path([
                  attribute.attribute("stroke-linecap", "round"),
                  attribute.attribute("stroke-linejoin", "round"),
                  attribute.attribute("d", "M5 12h14m-7 7V5"),
                  attribute.attribute("stroke-width", "2"),
                ]),
              ],
            ),
          ],
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
      html.th([attribute.class("flex justify-between")], [
        html.span([], [html.text(definition.description)]),
        ..{
          case definition.is_automatic_withdrawal {
            True -> [
              html.div([attribute.class("badge badge-primary")], [
                html.text("Automatic"),
              ]),
            ]
            False -> []
          }
        }
      ]),
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
  html.dialog([attribute.class("modal"), attribute.id("definition_modal")], [
    html.div([attribute.class("modal-box")], [
      html.form([attribute.method("dialog")], [
        html.button(
          [
            attribute.class(
              "btn btn-sm btn-circle btn-ghost absolute right-2 top-2",
            ),
          ],
          [
            html.svg(
              [
                attribute.class("h-6 w-6"),
                attribute.attribute("fill", "none"),
                attribute.attribute("viewBox", "0 0 24 24"),
              ],
              [
                svg.path([
                  attribute.attribute("stroke", "currentColor"),
                  attribute.attribute("stroke-linecap", "round"),
                  attribute.attribute("stroke-linejoin", "round"),
                  attribute.attribute("stroke-width", "2"),
                  attribute.attribute("d", "M6 18 17.94 6M18 18 6.06 6"),
                ]),
              ],
            ),
          ],
        ),
      ]),
      html.h3([attribute.class("font-bold text-lg")], [
        html.text("Edit Definition"),
      ]),
      html.form(
        [
          attribute.class("flex flex-col space-y-2"),
          hx.post("/admin/definitions/" <> id.unwrap(definition.id)),
        ],
        [
          html.input([
            attribute.type_("hidden"),
            attribute.name("id"),
            attribute.value(id.unwrap(definition.id)),
          ]),
          html.label([attribute.class("form-control w-full max-w-xs")], [
            html.input([
              attribute.class("input input-bordered w-full max-w-xs"),
              attribute.value(definition.description),
              attribute.placeholder("Description"),
              attribute.name("description"),
              attribute.required(True),
            ]),
          ]),
          html.div([attribute.class("form-control w-full max-w-xs")], [
            html.label([attribute.class("label cursor-pointer")], [
              html.span([attribute.class("label-text")], [
                html.text("Is Automatic?"),
              ]),
              html.input([
                attribute.class("checkbox"),
                attribute.name("is_automatic_withdrawal"),
                attribute.type_("checkbox"),
                attribute.checked(definition.is_automatic_withdrawal),
              ]),
            ]),
          ]),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(
              definition.amount |> formatters.format_float(2, None),
            ),
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
                    attribute.selected(f == definition.frequency),
                    attribute.value(definition.encode_frequency(f)),
                  ],
                  formatters.format_frequency(f),
                )
              }),
          ),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(definition.start_date |> formatters.format_date),
            attribute.name("start_date"),
            attribute.type_("date"),
            attribute.required(True),
          ]),
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.value(
              definition.end_date
              |> option.map(formatters.format_date)
              |> option.unwrap(""),
            ),
            attribute.name("end_date"),
            attribute.type_("date"),
          ]),
          html.div([attribute.class("modal-action")], [
            html.button(
              [attribute.class("btn btn-primary"), attribute.type_("submit")],
              [
                html.text("Save"),
                html.svg(
                  [
                    attribute.class("h-6 w-6"),
                    attribute.attribute("fill", "none"),
                    attribute.attribute("viewBox", "0 0 24 24"),
                  ],
                  [
                    svg.path([
                      attribute.attribute("stroke", "currentColor"),
                      attribute.attribute("stroke-linecap", "round"),
                      attribute.attribute("stroke-linejoin", "round"),
                      attribute.attribute("stroke-width", "2"),
                      attribute.attribute(
                        "d",
                        "M11 16h2m6.707-9.293-2.414-2.414A1 1 0 0 0 16.586 4H5a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1V7.414a1 1 0 0 0-.293-.707ZM16 20v-6a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v6h8ZM9 4h6v3a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1V4Z",
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ]),
  ])
}
