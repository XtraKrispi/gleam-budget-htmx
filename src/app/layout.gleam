import gleam/option.{None}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre_hx as hx
import utils/list as my_list

pub fn with_page_shell(content: List(Element(t))) -> Element(t) {
  html.html([], [
    html.head([], [
      html.title([], "Budget"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/css/app.css"),
      ]),
      html.script([attribute.src("https://unpkg.com/htmx.org@2.0.0")], ""),
      html.script(
        [attribute.src("https://unpkg.com/hyperscript.org@0.9.12")],
        "",
      ),
    ]),
    html.body([attribute.class("w-screen")], content),
  ])
}

pub fn with_layout(content: Element(t)) -> List(Element(t)) {
  let menu_items = [
    html.li([], [html.a([attribute.href("/")], [html.text("Home")])]),
    html.li([], [
      html.a([attribute.href("/admin/definitions")], [html.text("Definitions")]),
    ]),
    html.li([], [html.a([attribute.href("/archive")], [html.text("Archive")])]),
  ]

  [
    html.div(
      [
        attribute.class("toast toast-top toast-end z-[1000]"),
        attribute.id("toast-container"),
      ],
      [],
    ),
    html.div([attribute.class("navbar bg-base-100"), hx.boost(True)], [
      html.div([attribute.class("navbar-start")], [
        html.div([attribute.class("dropdown")], [
          html.div(
            [
              attribute.role("button"),
              attribute.attribute("tabindex", "0"),
              attribute.class("btn btn-ghost lg:hidden"),
            ],
            [
              html.svg(
                [
                  attribute.class("h-6 w-6"),
                  attribute.attribute("fill", "none"),
                  attribute.attribute("viewBox", "0 0 24 24"),
                  attribute.attribute("stroke", "currentColor"),
                ],
                [
                  svg.path([
                    attribute.attribute("stroke-linecap", "round"),
                    attribute.attribute("stroke-linejoin", "round"),
                    attribute.attribute("stroke-width", "2"),
                    attribute.attribute("d", "M4 6h16M4 12h8m-8 6h16"),
                  ]),
                ],
              ),
            ],
          ),
          html.ul(
            [
              attribute.class(
                "menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52",
              ),
            ],
            menu_items,
          ),
        ]),
        html.a([attribute.class("btn btn-ghost text-xl"), attribute.href("/")], [
          html.text("budget"),
        ]),
        html.div([attribute.class("hidden lg:flex")], [
          html.ul([attribute.class("menu menu-horizontal px-1")], menu_items),
        ]),
      ]),
    ]),
    content,
  ]
  |> with_page_shell
  |> my_list.singleton
}

pub type AlertType {
  Info
  Success
  Warning
  Error
}

pub fn add_toast(content: Element(t), alert_type: AlertType) -> Element(t) {
  html.div(
    [
      attribute.attribute("hx-swap-oob", "beforeend"),
      attribute.id("toast-container"),
    ],
    [
      html.div(
        [
          hx.get("/toast/clear"),
          hx.swap(hx.OuterHTML, None),
          hx.trigger([hx.Event("load", [hx.Delay(hx.Seconds(3))])]),
          attribute.class("alert"),
          attribute.classes([
            #("alert-info", alert_type == Info),
            #("alert-success", alert_type == Success),
            #("alert-warning", alert_type == Warning),
            #("alert-error", alert_type == Error),
          ]),
        ],
        [content],
      ),
    ],
  )
}
