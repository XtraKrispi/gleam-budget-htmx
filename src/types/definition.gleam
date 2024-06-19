import birl.{type Day}
import gleam/dynamic.{
  type DecodeError, type DecodeErrors, type Dynamic, DecodeError,
}
import gleam/float
import gleam/int
import gleam/option.{type Option}
import gleam/result
import types/id.{type Id}

pub type Definition {
  Definition(
    id: Id(Definition),
    description: String,
    amount: Float,
    frequency: Frequency,
    start_date: Day,
    end_date: Option(Day),
  )
}

pub type Frequency {
  OneTime
  BiWeekly
  Monthly
}

pub fn frequencies() {
  [OneTime, BiWeekly, Monthly]
}

pub fn parse_frequency(val: String) -> Result(Frequency, Nil) {
  case val {
    "one-time" -> Ok(OneTime)
    "bi-weekly" -> Ok(BiWeekly)
    "monthly" -> Ok(Monthly)
    _ -> Error(Nil)
  }
}

pub fn encode_frequency(f: Frequency) -> String {
  case f {
    OneTime -> "one-time"
    BiWeekly -> "bi-weekly"
    Monthly -> "monthly"
  }
}

pub fn frequency_decoder(dyn: Dynamic) -> Result(Frequency, DecodeErrors) {
  use f_str <- result.try(dynamic.string(dyn))
  use f <- result.try(
    parse_frequency(f_str)
    |> result.map_error(fn(_) {
      [DecodeError(expected: "frequency", found: f_str, path: ["frequency"])]
    }),
  )
  Ok(f)
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
