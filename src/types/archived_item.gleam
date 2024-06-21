import birl.{type Day}
import gleam/dynamic.{type DecodeErrors, type Dynamic, DecodeError}
import types/id.{type Id}
import types/item.{type Item}

pub type ArchivedItem {
  ArchivedItem(
    id: Id(ArchivedItem),
    item_id: Id(Item),
    description: String,
    amount: Float,
    date: Day,
    action_date: Day,
    action: ArchiveAction,
  )
}

pub type ArchiveAction {
  Paid
  Skipped
}

pub fn archive_action_decoder(
  dyn: Dynamic,
) -> Result(ArchiveAction, DecodeErrors) {
  case dynamic.string(dyn) {
    Ok("paid") -> Ok(Paid)
    Ok("skipped") -> Ok(Skipped)
    Ok(s) ->
      Error([
        DecodeError(expected: "paid | skipped", found: s, path: [
          "archive_action",
        ]),
      ])
    Error(e) -> Error(e)
  }
}
