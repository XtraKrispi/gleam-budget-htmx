import birl.{type Day}
import birl/duration
import gleam/iterator.{type Iterator, type Step, Done, Next}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Lt}
import gleam/string
import types/definition.{type Definition}
import types/item.{type Item, Item}

fn compare_dates(day1: Day, day2: Day) -> order.Order {
  birl.compare(day_to_time(day1), day_to_time(day2))
}

pub fn get_items(definitions: List(Definition), end_date: Day) -> List(Item) {
  definitions
  |> list.map(get_items_from_definition)
  |> list.flat_map(fn(iter) {
    iterator.take_while(iter, fn(i: Item) {
      case compare_dates(i.date, end_date) {
        Lt | Eq -> True
        _ -> False
      }
    })
    |> iterator.to_list
  })
  |> list.sort(fn(a, b) {
    case compare_dates(a.date, b.date) {
      order.Eq -> string.compare(a.description, b.description)
      o -> o
    }
  })
}

fn get_items_from_definition(def: Definition) -> Iterator(Item) {
  case def.frequency {
    definition.OneTime ->
      iterator.once(fn() {
        Item(def.id, def.description, def.amount, def.start_date)
      })
    definition.BiWeekly ->
      iterator.unfold(
        Item(def.id, def.description, def.amount, def.start_date),
        iterate_item(_, duration.days(14), def.end_date),
      )
    definition.Monthly ->
      iterator.unfold(
        Item(def.id, def.description, def.amount, def.start_date),
        iterate_item(_, duration.months(1), def.end_date),
      )
  }
}

fn iterate_item(
  item: Item,
  factor: duration.Duration,
  end_date: Option(Day),
) -> Step(Item, Item) {
  let new_item =
    Item(
      ..item,
      date: birl.add(day_to_time(item.date), factor)
        |> birl.get_day,
    )
  case end_date {
    Some(d) ->
      case compare_dates(new_item.date, d) {
        Lt | Eq -> Next(new_item, new_item)
        _ -> Done
      }
    None -> Next(new_item, new_item)
  }
}

fn day_to_time(day: Day) {
  birl.from_erlang_local_datetime(
    #(#(day.year, day.month, day.date), #(0, 0, 0)),
  )
}
