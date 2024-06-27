import app/router
import app/web.{Context}
import based
import based_sqlite
import gleam/erlang/process
import gleam/io
import mist
import radiate
import wisp

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir(".")
    |> radiate.on_reload(fn(_state, path) {
      io.println("Change in " <> path <> ", reloading!")
    })
    |> radiate.start()

  use db <- based.register(based_sqlite.adapter("budget.db"))

  let assert Ok(_) =
    "CREATE TABLE IF NOT EXISTS definitions(id INTEGER PRIMARY KEY AUTOINCREMENT, identifier TEXT, description TEXT, amount REAL, frequency TEXT, start_date TEXT, end_date TEXT NULL, is_automatic_withdrawal INTEGER);"
    |> based.new_query
    |> based.execute(db)

  let assert Ok(_) =
    "CREATE TABLE IF NOT EXISTS archive(id INTEGER PRIMARY KEY AUTOINCREMENT, identifier TEXT, item_definition_identifier TEXT, description TEXT, amount REAL, date TEXT, action_date TEXT, action TEXT);"
    |> based.new_query
    |> based.execute(db)

  let assert Ok(_) =
    "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT, password_hash TEXT, name TEXT, password_reset_token TEXT);"
    |> based.new_query
    |> based.execute(db)

  let assert Ok(_) =
    "CREATE TABLE IF NOT EXISTS sessions(session_id TEXT PRIMARY KEY, user_id INTEGER, expiration_time TEXT);"
    |> based.new_query
    |> based.execute(db)

  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  // A context is constructed holding the static directory path and database
  let ctx = Context(static_directory: static_directory(), db: db)

  let assert Ok(_) =
    wisp.mist_handler(router.handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("budget_htmx")
  priv_directory <> "/static"
}
