import birl.{type Day, type Time, Day}
import gleam/dynamic.{type DecodeErrors, type Decoder, type Dynamic, DecodeError}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

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
  let split = string.split(val, "-") |> list.map(int.parse) |> result.all
  case split {
    Ok([y, m, d]) -> Ok(Day(y, m, d))
    _ -> Error(Nil)
  }
}

pub fn day_decoder(dyn: Dynamic) -> Result(Day, DecodeErrors) {
  use f_str <- result.try(dynamic.string(dyn))
  use f <- result.try(
    parse_day(f_str)
    |> result.replace_error([
      DecodeError(expected: "day", found: f_str, path: ["day"]),
    ]),
  )
  Ok(f)
}

pub fn time_decoder(dyn: Dynamic) -> Result(Time, DecodeErrors) {
  use t_str <- result.try(dynamic.string(dyn))
  use t <- result.try(
    birl.parse(t_str)
    |> result.replace_error([
      DecodeError(expected: "time", found: t_str, path: ["time"]),
    ]),
  )
  Ok(t)
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
