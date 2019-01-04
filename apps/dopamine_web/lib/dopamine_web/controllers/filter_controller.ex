defmodule DopamineWeb.FilterController do
  use DopamineWeb, :controller

  def create(conn, data) do
    owning_user = conn.path_params["user_id"]

    session = conn.assigns.session
    user = session.user

    current_username = Dopamine.Accounts.User.matrix_id(user)

    data = %{data | "user_id" => user.id}

    if owning_user == current_username do
      {:ok, filter} = Dopamine.Filters.create_filter(data)
      conn |> json(%{filter_id: filter.id})
    else
      conn |> json(%{})
    end
  end

  def get(conn, %{"user_id" => user_id, "filter_id" => filter_id}) do
    filter = Dopamine.Filters.get_filter(user_id, filter_id)

    # TODO - remove anything that's null
    conn
    |> json(%{
      event_fields: filter.event_fields,
      event_format: filter.event_format,
      presence: filter.presence,
      account_data: filter.account_data,
      room: filter.room
    })
  end
end
