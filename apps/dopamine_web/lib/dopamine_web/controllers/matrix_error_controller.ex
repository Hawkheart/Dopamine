defmodule DopamineWeb.MatrixErrorController do
  use Phoenix.Controller

  def call(conn, {:error, :ratelimited}) do
    conn
    |> put_status(401)
    |> json(%{errcode: "whatever"})
  end

  def call(conn, {:error, :forbidden}) do
    call conn, {:error, :forbidden, "Aaa forbidden response"}
  end

  def call(conn, {:error, :forbidden, msg}) do
    conn
    |> put_status(403)
    |> json(%{errcode: "M_FORBIDDEN", error: msg})
  end
end
