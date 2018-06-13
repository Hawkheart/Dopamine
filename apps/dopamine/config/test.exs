use Mix.Config

# Configure your database
config :dopamine, Dopamine.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dopamine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
