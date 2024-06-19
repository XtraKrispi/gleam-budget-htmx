import birl.{type Day}
import gleam/float
import gleam/int
import gleam/option.{type Option}
import gleam/string
import gleam/string_builder.{type StringBuilder}
import types/definition.{type Frequency, BiWeekly, Monthly, OneTime}

fn split_thousands(data: Int, separator: String, accum: StringBuilder) {
  let divided = data / 1000
  case divided == 0 {
    True ->
      accum
      |> string_builder.prepend(int.to_string(data))
      |> string_builder.to_string
    False -> {
      let assert Ok(remainder) = int.remainder(data, 1000)
      split_thousands(
        data / 1000,
        separator,
        accum
          |> string_builder.prepend(int.to_string(remainder))
          |> string_builder.prepend(separator),
      )
    }
  }
}

pub fn float_to_string(data: Float, decimal_places: Int) {
  let assert Ok(#(before, after)) =
    data |> float.to_string |> string.split_once(".")

  before
  <> case decimal_places == 0 {
    True -> ""
    False -> "." <> string.pad_right(after, decimal_places, "0")
  }
}

pub fn format_float(
  data: Float,
  decimal_places: Int,
  thousands_separator: Option(String),
) {
  let assert Ok(factor) = int.power(10, int.to_float(decimal_places))
  let rounded =
    data *. factor
    |> float.round
    |> int.to_float
    |> fn(f) { f /. factor }

  let assert Ok(#(before_decimal, after_decimal)) =
    rounded |> float.to_string |> string.split_once(".")

  let assert Ok(before_int) = int.parse(before_decimal)
  thousands_separator
  |> option.map(split_thousands(before_int, _, string_builder.new()))
  |> option.unwrap(before_decimal)
  <> case decimal_places == 0 {
    True -> ""
    False -> "." <> string.pad_right(after_decimal, decimal_places, "0")
  }
}

pub fn format_frequency(frequency: Frequency) {
  case frequency {
    OneTime -> "One Time"
    BiWeekly -> "Bi-weekly"
    Monthly -> "Monthly"
  }
}

pub fn format_date(date: Day) {
  string_builder.new()
  |> string_builder.append(int.to_string(date.year))
  |> string_builder.append("-")
  |> string_builder.append(string.pad_left(int.to_string(date.month), 2, "0"))
  |> string_builder.append("-")
  |> string_builder.append(string.pad_left(int.to_string(date.date), 2, "0"))
  |> string_builder.to_string
}
