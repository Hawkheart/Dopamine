defmodule Dopamine.Filters do
  alias Dopamine.Filters.Filter

  import Ecto.Query, only: [from: 2]

  def create_filter(data) do
    %Filter{} |> Filter.changeset(data) |> Dopamine.Repo.insert()
  end

  def get_filter(_user_id, filter_id) do
    query = from(f in Filter, where: f.id == ^filter_id)

    Dopamine.Repo.one!(query)
  end
end
