import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre_hx as hx

pub fn with_layout(content: Element(t)) -> Element(t) {
  let menu_items = [
    html.li([], [html.a([attribute.href("/")], [html.text("Home")])]),
    html.li([], [
      html.a([attribute.href("/admin/definitions")], [html.text("Definitions")]),
    ]),
    html.li([], [html.a([attribute.href("/archive")], [html.text("Archive")])]),
  ]
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
    html.body([attribute.class("w-screen")], [
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
          html.a(
            [attribute.class("btn btn-ghost text-xl"), attribute.href("/")],
            [html.text("budget")],
          ),
          html.div([attribute.class("hidden lg:flex")], [
            html.ul([attribute.class("menu menu-horizontal px-1")], menu_items),
          ]),
        ]),
      ]),
      content,
    ]),
  ])
}
