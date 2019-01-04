defmodule DopamineWeb.AccountDataController do
  use DopamineWeb, :controller

  import Ecto.Query, only: [from: 2]

  def put_global(conn, _params) do
    type = conn.path_params["type"]

    contents = conn.body_params
    user = conn.assigns.user

    current_data =
      Dopamine.Repo.one(
        from(d in Dopamine.Accounts.Data,
          where: d.user_id == ^user.id and d.type == ^type and is_nil(d.room_id)
        )
      )

    data =
      if not is_nil(current_data) do
        current_data
        |> Ecto.Changeset.cast(%{content: contents}, [:content])
        |> Dopamine.Repo.insert_or_update!()
      else
        account_data = %Dopamine.Accounts.Data{
          type: type,
          user_id: user.id,
          room_id: nil,
          content: contents
        }

        Dopamine.Repo.insert!(account_data)
      end

    Dopamine.PubSub.send_to_user(user.username, {:account_data, data})

    conn |> json(%{})
  end
end
