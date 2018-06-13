defmodule DopamineWeb.AuthController do
  use DopamineWeb, :controller

  alias DopamineWeb.Forms.Registration, as: Registration

  plug DopamineWeb.Plugs.Ratelimit

  action_fallback DopamineWeb.MatrixErrorController

  def register(conn, %{"auth" => %{"type" => auth_type} = auth} = params) do
    case Registration.from_map(params) do
      {:ok, params} -> text(conn, "Got parameters")
      {:error, _err} -> {:error, :forbidden}
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
    render(conn, "success.json", username: username)
  end

end
