import gleam/result
import gleeunit
import gleeunit/should
import utils/decoders
import utils/formatters

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn decode_date_test() {
  let date_str = "2024-06-14"
  decoders.parse_day(date_str)
  |> result.map(formatters.format_date)
  |> should.equal(Ok(date_str))
}
//TODO:
// Test for float formatter, positive negative, < 1
// test for all formatters/parsers
