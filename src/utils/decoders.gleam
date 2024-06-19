import gleam/dynamic.{type Decoder}
import gleam/result

pub fn map(decoder: Decoder(a), f: fn(a) -> b) -> Decoder(b) {
  fn(dyn) {
    dyn
    |> decoder
    |> result.map(f)
  }
}

pub fn try(decoder: Decoder(a), f: fn(a) -> Decoder(b)) -> Decoder(b) {
  fn(dyn) {
    case decoder(dyn) {
      Ok(r) -> {
        f(r)(dyn)
      }
      Error(err) -> Error(err)
    }
  }
}
