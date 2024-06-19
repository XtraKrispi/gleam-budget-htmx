import gleam/http/request.{get_header}
import gleam/result
import wisp.{type Request}

pub fn is_htmx(req: Request) -> Bool {
  get_header(req, "HX-Request") |> result.is_ok
}

pub fn is_boosted(req: Request) -> Bool {
  get_header(req, "HX-Boosted") |> result.is_ok
}
