use Mix.Config

config :dopamine, ecto_repos: [Dopamine.Repo]

import_config "#{Mix.env}.exs"
