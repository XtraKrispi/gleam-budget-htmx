import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn with_layout(content: Element(t)) -> Element(t) {
  html.html([], [
    html.head([], [
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
    html.body([attribute.class("w-screen")], [content]),
  ])
}
