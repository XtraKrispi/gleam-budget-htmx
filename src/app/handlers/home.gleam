import app/handlers/common.{error_toast, to_response}
import app/layout
import based.{type DB}
import birl
import birl/duration
import db/archive as archive_db
import db/definitions as definition_db
import gleam/list
import gleam/result
import gleam/string
import htmx/request
import logic/items
import page_templates/home
import types/user.{type User}
import utils/decoders
import utils/list as my_list
import wisp

pub fn home_page(req, user, db) {
  let query_strings = wisp.get_query(req)
  let end_date =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "end_date" })
    |> result.try(fn(qs) { decoders.parse_day(qs.1) })
    |> result.unwrap(birl.get_day(birl.add(birl.now(), duration.days(21))))

  let amount_in_bank =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "amount_in_bank" })
    |> result.try(fn(qs) { decoders.parse_float(qs.1) })

  let amount_left_over =
    query_strings
    |> list.find(fn(qs) { string.lowercase(qs.0) == "amount_left_over" })
    |> result.try(fn(qs) { decoders.parse_float(qs.1) })

  case request.is_htmx(req) && !request.is_boosted(req) {
    True -> home_content(user, end_date, amount_in_bank, amount_left_over, db)
    False ->
      home.full_page(end_date, amount_in_bank, amount_left_over)
      |> layout.with_layout(user)
      |> to_response(200)
      |> wisp.set_header("NEEDS_AUTH", "Hello")
  }
}

pub fn home_content(
  user: User,
  end_date,
  amount_in_bank: Result(Float, Nil),
  amount_left_over: Result(Float, Nil),
  db: DB,
) {
  let definitions = definition_db.get_all(user.email, db)
  let archive = archive_db.get_all(user.email, db)

  case definitions, archive {
    Ok(defs), Ok(a) -> {
      let items =
        items.get_items(defs, end_date)
        |> list.filter(fn(item) {
          !list.any(a, fn(arch) {
            item.definition_id == arch.item_definition_id
            && item.date == arch.date
          })
        })
      home.content(items, end_date, amount_in_bank, amount_left_over)
      |> my_list.singleton
      |> to_response(200)
    }
    _, _ ->
      error_toast(
        "There was an issue fetching items, please refresh and try again.",
      )
  }
}
