import lustre/attribute
import lustre/element/html
import lustre_hx as hx

pub fn landing_page() {
  html.div(
    [
      attribute.class(
        "bg-base-200 hero min-h-screen min-w-screen flex flex-col justify-center",
      ),
    ],
    [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
        html.div([attribute.class("text-center lg:text-left")], [
          html.h1([attribute.class("text-5xl font-bold")], [
            html.text("Reset Password"),
          ]),
          html.p([attribute.class("py-6")], [
            html.text("Please enter the email you signed up with"),
          ]),
        ]),
        html.div(
          [
            attribute.class(
              "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
            ),
          ],
          [
            html.form(
              [attribute.class("card-body"), hx.post("/reset_password")],
              [
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
                    attribute.name("email"),
                    attribute.attribute("hx-validate", "true"),
                  ]),
                ]),
                html.div([attribute.class("form-control mt-6")], [
                  html.button([attribute.class("btn btn-primary")], [
                    html.text("Reset Password"),
                  ]),
                ]),
              ],
            ),
          ],
        ),
      ]),
    ],
  )
}

pub fn invalid_token_page() {
  html.div(
    [
      attribute.class(
        "bg-base-200 hero min-h-screen min-w-screen flex flex-col justify-center",
      ),
    ],
    [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
        html.div([attribute.class("text-center lg:text-left")], [
          html.h1([attribute.class("text-5xl font-bold")], [
            html.text("Reset Password"),
          ]),
          html.p([attribute.class("py-6")], [
            html.text("Please enter the email you signed up with"),
          ]),
        ]),
        html.div(
          [
            attribute.class(
              "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
            ),
          ],
          [
            html.form(
              [attribute.class("card-body"), hx.post("/reset_password")],
              [
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
                    attribute.name("email"),
                    attribute.attribute("hx-validate", "true"),
                  ]),
                ]),
                html.div([attribute.class("form-control mt-6")], [
                  html.button([attribute.class("btn btn-primary")], [
                    html.text("Reset Password"),
                  ]),
                ]),
              ],
            ),
          ],
        ),
      ]),
    ],
  )
}

pub fn reset_page() {
  html.div(
    [
      attribute.class(
        "bg-base-200 hero min-h-screen min-w-screen flex flex-col justify-center",
      ),
    ],
    [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
        html.div([attribute.class("text-center lg:text-left")], [
          html.h1([attribute.class("text-5xl font-bold")], [
            html.text("Reset Password"),
          ]),
          html.p([attribute.class("py-6")], [
            html.text("Please enter the email you signed up with"),
          ]),
        ]),
        html.div(
          [
            attribute.class(
              "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
            ),
          ],
          [
            html.form(
              [attribute.class("card-body"), hx.post("/reset_password")],
              [
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
                    attribute.name("email"),
                    attribute.attribute("hx-validate", "true"),
                  ]),
                ]),
                html.div([attribute.class("form-control mt-6")], [
                  html.button([attribute.class("btn btn-primary")], [
                    html.text("Reset Password"),
                  ]),
                ]),
              ],
            ),
          ],
        ),
      ]),
    ],
  )
}
