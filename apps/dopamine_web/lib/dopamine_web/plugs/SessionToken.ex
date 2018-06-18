defmodule DopamineWeb.Plugs.SessionToken do
  import Plug.Conn

  alias DopamineWeb.MatrixErrorController

  def init(default) do
    default
  end

  def call(conn, _default) do
    # Make sure the query parameters are fetched
    conn = fetch_query_params(conn)
    token = conn.query_params["auth_token"]

    # Figure out where the token is and extract it
    result = if token != nil do
      {:ok, token}
    else
      header = get_req_header(conn, "authorization")
      parse_token(header)
    end

    with {:ok, token} <- result,
         session when not is_nil(session) <- Dopamine.Accounts.get_session(token) do
      conn
      |> assign(:session, session)
    else
      {:error, err} -> send_error(conn, {:error, err})
      nil -> send_error(conn, {:error, :bad_token})
      _ -> send_error(conn, {:error, :unknown})
    end
  end

  defp send_error(conn, err) do
    # Just call out to the error handler and halt.
    conn
    |> MatrixErrorController.call(err)
    |> halt
  end

  defp parse_token([]) do
    {:error, :no_token}
  end

  defp parse_token(token) do
    token = String.split(to_string(token), " ")
    if length(token) == 2 do
      [_method, token] = token
      {:ok, token}
    else
      {:error, :bad_token}
    end
  end
end
