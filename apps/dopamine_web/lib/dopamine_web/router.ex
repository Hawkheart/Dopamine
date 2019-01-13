defmodule DopamineWeb.Router do
  use DopamineWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated do
    plug(:accepts, ["json"])
    plug(DopamineWeb.Plugs.SessionToken)
  end

  scope "/_matrix/client", DopamineWeb do
    pipe_through(:api)

    get("/versions", InfoController, :client_versions)

    post("/r0/register", AuthController, :register)
    get("/r0/login", AuthController, :login_types)
    post("/r0/login", AuthController, :login)
  end

  scope "/_matrix/client/r0", DopamineWeb do
    pipe_through(:authenticated)

    post("/logout", AuthController, :logout)

    post("/createRoom", RoomController, :create)
    post("/join/:room_id", RoomController, :join)
    get("/rooms/:room_id/initialSync", RoomController, :initial_sync)
    put("/rooms/:room_id/send/:type/:txn_id", RoomController, :send_event)
    get("/publicRooms", RoomController, :get_public)
    post("/publicRooms", RoomController, :get_public)

    put("/rooms/:room_id/state/:type", RoomController, :set_state)
    put("/rooms/:room_id/state/:type/:state_key", RoomController, :set_state)

    get("/directory/list/room/:room_id", RoomController, :get_visibility)
    put("/directory/list/room/:room_id", RoomController, :set_visibility)

    get("/pushrules", PresenceController, :get_push)

    post("/user/:user_id/filter", FilterController, :create)
    get("/user/:user_id/filter/:filter_id", FilterController, :get)

    put("/user/:user_id/account_data/:type", AccountDataController, :put_global)

    get("/sync", SyncController, :sync)

    scope "/profile" do
      get("/:user_id", ProfileController, :get)
      put("/:user_id/displayname", ProfileController, :set_name)
    end

    get("/account/3pid", ProfileController, :list_3pids)
  end

  scope "/_matrix/client/r0/presence", DopamineWeb do
    pipe_through(:authenticated)

    put("/:user_id/status", PresenceController, :update)
  end

  scope "/_matrix/federation/v1", DopamineWeb do
    pipe_through(:api)

    get("/version", InfoController, :server_version)
  end
end
