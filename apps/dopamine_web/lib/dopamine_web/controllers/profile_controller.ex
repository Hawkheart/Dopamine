defmodule DopamineWeb.ProfileController do
  use DopamineWeb, :controller

  def list_3pids(conn, _data) do
    conn |> json(%{threepids: []})
  end

  def get(conn, _data) do
    user_id = conn.path_params["user_id"]

    ["@" <> username, _host] = String.split(user_id, ":")

    user = Dopamine.Accounts.get(username)

    conn
    |> json(%{displayname: user.display_name})
  end

  def set_name(conn, data) do
    new_name = data["displayname"]
    user = conn.assigns.session.user
    Dopamine.Accounts.set_name(user, new_name)
    conn |> json(%{})
  end
end
