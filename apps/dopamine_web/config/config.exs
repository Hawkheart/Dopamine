# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :dopamine_web,
  namespace: DopamineWeb,
  ecto_repos: [Dopamine.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :dopamine_web, DopamineWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "g3rOoiaWH7vj7aFjxd4Kf2Iv1nqqLCK4p7JlnJrjJ9brSjXXCjMBc5tNGe7lXhzL",
  render_errors: [view: DopamineWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: DopamineWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :dopamine_web, :generators,
  context_app: :dopamine

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4,
                                 cleanup_interval_ms: 60_000 * 10]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
