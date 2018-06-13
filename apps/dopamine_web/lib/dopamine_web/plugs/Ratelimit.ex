defmodule DopamineWeb.Plugs.Ratelimit do
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  def init(default) do
    default
  end

  def call(conn, _default) do
    case Hammer.check_rate("action-test", 60_000, 30) do
      {:allow, _count} -> conn
      {:deny, _limit} -> send_error conn
    end
  end

  defp send_error(conn) do
    conn
    |> put_status(401)
    |> json(%{error: "Rate limit exceeded.", errcode: "M_LIMIT_EXCEEDED"})
    |> halt
  end
end
