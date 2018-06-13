defmodule DopamineWeb.Router do
  use DopamineWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/_matrix/client", DopamineWeb do
    pipe_through :api

    get "/versions", InfoController, :client_versions

    post "/r0/register", AuthController, :register

    post "/r0/login", AuthController, :login
  end

  scope "/_matrix/federation/v1", DopamineWeb do
    pipe_through :api

    get "/version", InfoController, :server_version
  end
end
