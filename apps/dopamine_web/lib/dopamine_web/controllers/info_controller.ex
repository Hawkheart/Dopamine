defmodule DopamineWeb.InfoController do
  use DopamineWeb, :controller

  def client_versions(conn, _params) do
    render(conn, "client_versions.json")
  end

  def server_version(conn, _params) do
    render(conn, "server_version.json")
  end

  def protocol_list(conn, _params) do
    conn |> json(%{})
  end
end
