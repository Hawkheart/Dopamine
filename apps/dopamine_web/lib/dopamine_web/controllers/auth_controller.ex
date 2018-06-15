defmodule DopamineWeb.AuthController do
  use DopamineWeb, :controller

  plug DopamineWeb.Plugs.Ratelimit

  action_fallback DopamineWeb.MatrixErrorController

  def register(conn, %{"auth" => %{"type" => "m.login.password"},
                       "user" => username,
                       "password" => password}) do
    case Dopamine.Accounts.create_user(username, password) do
      {:ok, user} -> json conn, %{"msg": "successfully created user!"}
      {:error, err} -> json conn, %{"msg": "failed to create user."}
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
    case Dopamine.Accounts.verify_user(username, password) do
      {:ok, user} -> json conn, %{"msg": "successfully logged in!"}
      {:error, reason} -> json conn, %{"msg": "failed to log in"}
    end
  end

end
