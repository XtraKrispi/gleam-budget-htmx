import lustre/attribute
import lustre/element/html
import lustre/element/svg
import lustre_hx as hx

pub fn full_page() {
  html.div(
    [
      attribute.class("hero bg-base-200 min-h-screen"),
      hx.hyper_script(
        "on hideRegistrationModal from body call registration_modal.close() end",
      ),
    ],
    [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
        html.div([attribute.class("text-center lg:text-left")], [
          html.h1([attribute.class("text-5xl font-bold")], [
            html.text("Login now!"),
          ]),
          html.p([attribute.class("pt-6")], [
            html.text(
              "Please log in to the Budget system to see what you have upcoming and to make any changes!",
            ),
          ]),
          html.p([attribute.class("py-2")], [
            html.text("Don't have an account? No problem! Sign up here!"),
          ]),
          html.button(
            [
              attribute.class("btn btn-primary"),
              hx.hyper_script(
                "on click call registration_modal.showModal() end",
              ),
            ],
            [html.text("Sign Up")],
          ),
        ]),
        html.div(
          [
            attribute.class(
              "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
            ),
          ],
          [
            html.form([attribute.class("card-body")], [
              html.div([attribute.class("form-control")], [
                html.label([attribute.class("label")], [
                  html.span([attribute.class("label-text")], [
                    html.text("Email"),
                  ]),
                ]),
                html.input([
                  attribute.type_("email"),
                  attribute.placeholder("email"),
                  attribute.class("input input-bordered"),
                  attribute.required(True),
                  attribute.autofocus(True),
                ]),
              ]),
              html.div([attribute.class("form-control")], [
                html.label([attribute.class("label")], [
                  html.span([attribute.class("label-text")], [
                    html.text("Password"),
                  ]),
                ]),
                html.input([
                  attribute.type_("email"),
                  attribute.placeholder("email"),
                  attribute.class("input input-bordered"),
                  attribute.required(True),
                ]),
                html.label([attribute.class("label")], [
                  html.a([attribute.class("label-text-alt link link-hover")], [
                    html.text("Forgot password?"),
                  ]),
                ]),
              ]),
              html.div([attribute.class("form-control mt-6")], [
                html.button([attribute.class("btn btn-primary")], [
                  html.text("Login"),
                ]),
              ]),
            ]),
          ],
        ),
      ]),
      render_registration_modal(),
    ],
  )
}

pub fn render_registration_modal() {
  html.dialog([attribute.class("modal"), attribute.id("registration_modal")], [
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
      html.h3([attribute.class("font-bold text-lg")], [html.text("Sign Up")]),
      html.form([attribute.class("flex flex-col space-y-2")], [
        html.label([attribute.class("form-control w-full max-w-xs mt-2")], [
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.placeholder("Email"),
            attribute.name("email"),
            attribute.required(True),
            attribute.type_("email"),
            attribute.attribute("hx-validate", "true"),
          ]),
        ]),
        html.label([attribute.class("form-control w-full max-w-xs mt-2")], [
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.placeholder("Password"),
            attribute.name("password"),
            attribute.required(True),
            attribute.type_("password"),
            attribute.attribute("hx-validate", "true"),
          ]),
        ]),
        html.label([attribute.class("form-control w-full max-w-xs mt-2")], [
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.placeholder("Password Confirmation"),
            attribute.name("password_confirm"),
            attribute.required(True),
            attribute.type_("password"),
            attribute.attribute("hx-validate", "true"),
          ]),
        ]),
        html.label([attribute.class("form-control w-full max-w-xs mt-2")], [
          html.input([
            attribute.class("input input-bordered w-full max-w-xs"),
            attribute.placeholder("Name"),
            attribute.name("name"),
            attribute.required(True),
            attribute.type_("text"),
          ]),
        ]),
        html.div([attribute.class("modal-action")], [
          html.button(
            [attribute.class("btn btn-primary"), attribute.type_("submit")],
            [html.text("Sign Up")],
          ),
        ]),
      ]),
    ]),
  ])
}
