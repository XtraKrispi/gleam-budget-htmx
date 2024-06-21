import lustre/attribute
import lustre/element/html

pub fn full_page() {
  html.div([attribute.class("px-20 py-10")], [
    html.header([attribute.class("prose lg:prose-xl flex space-x-4")], [
      html.h2([], [html.text("Archive")]),
    ]),
  ])
}
