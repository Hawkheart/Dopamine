defmodule DopamineWeb.AuthController do
  use DopamineWeb, :controller

  alias Dopamine.Accounts

  alias :crypto, as: Crypto

  plug(DopamineWeb.Plugs.Ratelimit)

  def register(
        conn,
        %{"auth" => %{"type" => "m.login.password"}} = params
      ) do
    {:ok, data} = DopamineWeb.Forms.RegisterForm.validate(params)

    username = data.username
    password = data.password

    device_id =
      if not is_nil(data.device_id),
        do: data.device_id,
        else: Base.encode16(Crypto.strong_rand_bytes(16))

    with {:ok, %{user: user, device: device, session: session}} <-
           Accounts.create_user(username, password, device_id) do
      user_id = Accounts.User.matrix_id(user)
      resp = %{user_id: user_id, device_id: device.public_id, access_token: session.token}

      conn
      |> json(resp)
    else
      {:error, errcode} when is_atom(errcode) ->
        {:error, errcode}

      {:error, changeset = %Ecto.Changeset{}} ->
        IO.inspect(changeset)
        # TODO - give a better error code
        {:error, :unknown}

      err ->
        IO.inspect(err)
        {:error, :unknown}
    end
  end

  # Handles the case where there's no valid auth parameter.
  def register(conn, _params) do
    conn
    |> put_status(401)
    |> json(%{"flows" => [%{"stages" => ["m.login.password"]}]})
  end

  def login_types(conn, _data) do
    conn |> json(%{"flows" => [%{"type" => "m.login.password"}]})
  end

  @spec login(any(), any()) :: {:error, any()} | Plug.Conn.t()
  def login(conn, data) do
    device_id = Map.get(data, "device_id", Base.encode16(Crypto.strong_rand_bytes(16)))

    with {:ok, auth} <- DopamineWeb.Forms.AuthData.cast(data),
         {:ok, user} <- Accounts.verify_user(auth.identifier.user, auth.password),
         {:ok, device} <- Accounts.create_device(user, device_id),
         {:ok, session} <- Accounts.create_session(user, device) do
      conn
      |> json(%{
        access_token: session.token,
        device_id: session.device_id,
        user_id: Accounts.User.matrix_id(user)
      })
    else
      {:error, type} -> {:error, type}
      :error -> {:error, :unknown}
    end
  end

  def logout(conn, _params) do
    session = conn.assigns.session

    with {:ok, ^session} <- Accounts.delete_session(session) do
      conn
      |> json(%{})
    else
      _ -> {:error, :bad_token}
    end
  end
end
