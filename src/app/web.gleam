import based.{type DB}
import wisp.{type Request, type Response}

pub type Context {
  Context(static_directory: String, db: DB)
}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)

  use <- wisp.rescue_crashes()

  use req <- wisp.handle_head(req)

  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}
