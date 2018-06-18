defmodule DopamineWeb.AuthController do
  use DopamineWeb, :controller

  alias Dopamine.Accounts

  alias :crypto, as: Crypto

  plug DopamineWeb.Plugs.Ratelimit

  action_fallback DopamineWeb.MatrixErrorController

  def register(conn, %{"auth" => %{"type" => "m.login.password"},
                       "user" => username,
                       "password" => password} = params) do
    device_id = if not is_nil(params["device_id"]), do: params["device_id"], else: Base.encode16(Crypto.strong_rand_bytes(16))
    with {:ok, user} <- Accounts.create_user(username, password),
         {:ok, session} <- Accounts.create_session(user, device_id) do
      resp = %{device_id: device_id, access_token: session.token}
      conn
      |> json(resp)
    else
      {:error, errcode} when is_atom(errcode) -> {:error, errcode}
      err -> IO.inspect err; {:error, :unknown}
    end
  end

  # Handles the case where there's no valid auth parameter.
  def register(conn, params) do
    conn
    |> put_status(401)
    |> json(%{flows: [%{stages: ["m.login.password"]}]})
  end


  def login(conn, %{"type" => "m.login.password", 
                              "password" => password, 
			                        "user" => username} = params) do
    with {:ok, user} <- Accounts.verify_user(username, password),
         {:ok, session} <- Accounts.create_session(user, "aaaa") do

      json conn, %{token: session.token, device_id: session.device_id}
    else
      {:error, type} -> {:error, type}
      err -> IO.inspect err; {:error, :generic}
    end
  end

  def logout(conn, _params) do
    session = conn.assigns.session
    with {:ok, session} <- Accounts.delete_session(session) do
      conn
      |> json(%{})
    else
      _ -> {:error, :bad_token}
    end
  end

end
