import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/result
import gluid

pub opaque type Id(a) {
  Id(val: String)
}

pub fn new_id() -> Id(a) {
  Id(gluid.guidv4())
}

pub fn unwrap(id: Id(a)) -> String {
  id.val
}

pub fn wrap(val: String) -> Id(a) {
  Id(val)
}

pub fn decoder(dyn: Dynamic) -> Result(Id(a), DecodeErrors) {
  dyn
  |> dynamic.string
  |> result.map(Id)
}
