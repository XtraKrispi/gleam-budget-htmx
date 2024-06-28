import app/handlers/common.{error_toast, hydrate_item, to_response}
import app/layout
import based.{type DB}
import birl
import db/archive as archive_db
import gleam/http.{Post}
import gleam/io
import htmx/request
import lustre/element/html
import page_templates/archive as archive_page
import types/archived_item.{ArchivedItem}
import types/id
import types/item.{type Item}
import types/user.{type User}
import utils/list as my_list
import wisp.{type Request, type Response}

pub fn archive_page(req: Request, user: User, db: DB) -> Response {
  case request.is_htmx(req) && !request.is_boosted(req) {
    True -> {
      let archive_items = archive_db.get_all(user.email, db)
      case archive_items {
        Ok(items) ->
          archive_page.items(items)
          |> my_list.singleton
          |> to_response(200)
        Error(_) ->
          layout.add_toast(
            html.span([], [
              html.text(
                "There was a problem retrieving archive items. Please refresh and try again.",
              ),
            ]),
            layout.Error,
          )
          |> my_list.singleton
          |> to_response(200)
          |> wisp.set_header("HX-Reswap", "none")
      }
    }
    False ->
      archive_page.full_page()
      |> layout.with_layout(user)
      |> to_response(200)
  }
}

pub fn archive(req: Request, user: User, db: DB, action) {
  use <- wisp.require_method(req, Post)
  use form_data <- wisp.require_form(req)
  io.debug(form_data)
  case hydrate_item(form_data) {
    Ok(item) -> {
      io.debug("hydrated")
      case
        item
        |> convert_to_archive(action)
        |> archive_db.insert(user.email, db)
      {
        Ok(_) -> wisp.no_content() |> wisp.set_header("HX-Trigger", "reload")
        Error(_err) ->
          error_toast("Could not move to the archive, please try again.")
      }
    }
    Error(_err) -> error_toast("Bad request, please check your formatting.")
  }
}

fn convert_to_archive(item: Item, action) {
  ArchivedItem(
    id.new_id(),
    item.definition_id,
    item.description,
    item.amount,
    item.date,
    birl.now() |> birl.get_day,
    action,
  )
}
