use Mix.Config

# Configure your database
config :dopamine, Dopamine.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dopamine_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :dopamine, hostname: "localhost"
