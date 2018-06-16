defmodule DopamineWeb.Plugs.SessionToken do
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  def init(default) do
    default
  end

  def call(conn, _default) do
    with {:ok, token} <- parse_token(get_req_header(conn, "authorization")),
         session when not is_nil(session) <- Dopamine.Accounts.get_session token do
      conn
      |> assign(:session, session)
    else
      nil -> send_error conn, :not_found
      err -> send_error conn, err
    end
  end

  # TODO consolidate all these
  defp send_error(conn, err) do
    conn
    |> put_status(401)
    |> json(%{})
    |> halt
  end

  defp parse_token([]) do
    {:error, :no_token}
  end

  defp parse_token(token) do
    [_method, token] = String.split(to_string(token), " ")
    {:ok, token}
  end
end
