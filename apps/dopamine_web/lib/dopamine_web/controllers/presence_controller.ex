defmodule DopamineWeb.PresenceController do
  use DopamineWeb, :controller

  def update(conn, params) do
    updated_user = conn.path_params["user_id"]

    IO.puts(updated_user)

    session = conn.assigns.session
    user = session.user

    presence = params["presence"]
    status_msg = Map.get(params, "status_msg")

    current_user = Dopamine.Accounts.User.matrix_id(user)

    if updated_user == current_user do
      Dopamine.Accounts.set_presence(user, {presence, status_msg})
      conn |> json(%{})
    else
      # TODO - error code for "bad"
      {:error, :unknown}
    end
  end

  def get_push(conn, data) do
    conn |> json(%{})
  end

  def sync(conn, data) do
    {timeout, _} = data["timeout"] |> Integer.parse()

    :ok = Process.sleep(timeout)

    conn |> json(%{})
  end
end
