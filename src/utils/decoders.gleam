import birl.{type Day}
import gleam/dynamic.{type DecodeErrors, type Decoder, type Dynamic, DecodeError}
import gleam/float
import gleam/int
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

pub fn parse_day(val: String) -> Result(Day, Nil) {
  birl.parse(val)
  |> result.map(birl.get_day)
}

pub fn day_decoder(dyn: Dynamic) -> Result(Day, DecodeErrors) {
  use f_str <- result.try(dynamic.string(dyn))
  use f <- result.try(
    parse_day(f_str)
    |> result.map_error(fn(_) {
      [DecodeError(expected: "frequency", found: f_str, path: ["frequency"])]
    }),
  )
  Ok(f)
}

pub fn parse_float(val: String) -> Result(Float, Nil) {
  case float.parse(val) {
    Ok(f) -> Ok(f)
    Error(_) ->
      case int.parse(val) {
        Ok(i) -> Ok(int.to_float(i))
        Error(_) -> Error(Nil)
      }
  }
}
