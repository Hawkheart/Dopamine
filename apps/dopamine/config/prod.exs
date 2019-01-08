use Mix.Config

config :dopamine, Dopamine.Repo, url: System.get_env("DATABASE_URL"), ssl: true, pool_size: 2

config :dopamine, hostname: System.get_env("MATRIX_HOSTNAME")
