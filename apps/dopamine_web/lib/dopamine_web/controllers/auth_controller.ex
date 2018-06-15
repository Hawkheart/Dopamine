defmodule DopamineWeb.AuthController do
  use DopamineWeb, :controller

  alias Dopamine.Accounts

  plug DopamineWeb.Plugs.Ratelimit

  action_fallback DopamineWeb.MatrixErrorController

  def register(conn, %{"auth" => %{"type" => "m.login.password"},
                       "user" => username,
                       "password" => password}) do
    with {:ok, user} <- Accounts.create_user(username, password) do
      json conn, %{"msg": "user created successfully"}
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
         {:ok, session} <- Accounts.create_session(user) do
      json conn, %{"msg": "successfully logged in with session ID #{session.id}"}
    else
      _ -> json conn, %{"msg": "failed to log in"}
    end
  end

end
