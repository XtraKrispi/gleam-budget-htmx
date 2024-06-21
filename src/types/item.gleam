import birl.{type Day}
import gleam/json
import types/id.{type Id}
import utils/formatters

pub type Item {
  Item(id: Id(Item), description: String, amount: Float, date: Day)
}

pub fn item_to_json(item: Item) {
  json.object([
    #("id", json.string(id.unwrap(item.id))),
    #("description", json.string(item.description)),
    #("amount", json.float(item.amount)),
    #("date", json.string(formatters.format_date(item.date))),
  ])
  |> json.to_string
}
