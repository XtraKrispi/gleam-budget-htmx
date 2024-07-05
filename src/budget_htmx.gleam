import app/router
import app/web.{Context}
import based
import based_sqlite
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/io
import gleam/option.{Some}
import gleam/pair
import gleam/result
import gleam/string
import mist
import radiate
import types/mail_config.{
  type MailConfig, EmailAddress, Hostname, MailConfig, MailRecipient, Name,
  Password, Port, Relay, Username,
}
import wisp

fn hydrate_mail_config() -> Result(MailConfig, List(String)) {
  let get_env_value = fn(val: String) {
    env.get(val) |> result.replace_error(val)
  }
  let relay = get_env_value("BUDGET_SMTP_RELAY")
  let hostname = get_env_value("BUDGET_SMTP_HOSTNAME")
  let from_name = get_env_value("BUDGET_SMTP_FROM_NAME")
  let from_email = get_env_value("BUDGET_SMTP_FROM_EMAIL")
  let username = get_env_value("BUDGET_SMTP_USERNAME")
  let password = get_env_value("BUDGET_SMTP_PASSWORD")

  case relay, hostname, from_name, from_email, username, password {
    Ok(r), Ok(h), Ok(n), Ok(e), Ok(u), Ok(p) ->
      Ok(MailConfig(
        MailRecipient(EmailAddress(e), Some(Name(n))),
        Relay(r),
        Port(587),
        Username(u),
        Password(p),
        Hostname(h),
      ))
    _, _, _, _, _, _ ->
      result.partition([
        relay,
        hostname,
        from_name,
        from_email,
        username,
        password,
      ])
      |> pair.second
      |> Error
  }
}

pub fn main() {
  dot_env.load_default()
  let _ = case
    env.get("BUDGET_ENVIRONMENT")
    |> result.map(string.lowercase)
  {
    Ok("dev") ->
      radiate.new()
      |> radiate.add_dir(".")
      |> radiate.on_reload(fn(_state, path) {
        io.println("Change in " <> path <> ", reloading!")
      })
      |> radiate.start()
      |> result.replace(Nil)
      |> result.replace_error(Nil)
    _ -> Ok(Nil)
  }

  case hydrate_mail_config() {
    Ok(config) -> {
      use db <- based.register(based_sqlite.adapter("budget.db"))

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS definitions(id INTEGER PRIMARY KEY AUTOINCREMENT, identifier TEXT, description TEXT, amount REAL, frequency TEXT, start_date TEXT, end_date TEXT NULL, is_automatic_withdrawal INTEGER, user_id INTEGER);"
        |> based.new_query
        |> based.execute(db)

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS archive(id INTEGER PRIMARY KEY AUTOINCREMENT, identifier TEXT, item_definition_identifier TEXT, description TEXT, amount REAL, date TEXT, action_date TEXT, action TEXT, user_id INTEGER);"
        |> based.new_query
        |> based.execute(db)

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT, password_hash TEXT, name TEXT);"
        |> based.new_query
        |> based.execute(db)

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS sessions(session_id TEXT PRIMARY KEY, user_id INTEGER, expiration_time TEXT);"
        |> based.new_query
        |> based.execute(db)

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS scratch(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER UNIQUE, end_date TEXT, amount_in_bank REAL, amount_left_over REAL);"
        |> based.new_query
        |> based.execute(db)

      let assert Ok(_) =
        "CREATE TABLE IF NOT EXISTS password_reset_tokens (    
    user_id TEXT NOT NULL,    
    token TEXT NOT NULL UNIQUE,    
    token_expiry TEXT NOT NULL,    
    PRIMARY KEY (user_id, token)
    );"
        |> based.new_query
        |> based.execute(db)

      wisp.configure_logger()
      let secret_key_base =
        env.get("BUDGET_SECRET_KEY") |> result.unwrap(wisp.random_string(64))

      // A context is constructed holding the static directory path and database
      let ctx =
        Context(
          static_directory: static_directory(),
          db: db,
          mail_config: config,
          base_url: env.get("BUDGET_BASE_URL")
            |> result.unwrap("http://localhost:8000"),
        )

      let assert Ok(_) =
        wisp.mist_handler(router.handle_request(_, ctx), secret_key_base)
        |> mist.new
        |> mist.port(8000)
        |> mist.start_http

      // TODO: Create a running process here that will clean up the tokens and sessions tables
      // Use https://hexdocs.pm/gleam_erlang/gleam/erlang/process.html#start and https://hexdocs.pm/gleam_erlang/gleam/erlang/process.html#sleep

      process.sleep_forever()
    }
    Error(envs) -> {
      io.print_error(
        "Unable to get mail configuration.  The following environment variables are not set: "
        <> string.join(envs, ","),
      )
    }
  }
}

fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("budget_htmx")
  priv_directory <> "/static"
}
// TODO: Password reset 
// https://supertokens.com/blog/implementing-a-forgot-password-flow
