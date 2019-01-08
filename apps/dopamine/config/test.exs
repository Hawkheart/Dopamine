use Mix.Config

# Configure your database
config :dopamine, Dopamine.Repo,
  username: "postgres",
  password: "postgres",
  database: "dopamine_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Significantly speed up logins
config :argon2_elixir, t_cost: 2, m_cost: 8
