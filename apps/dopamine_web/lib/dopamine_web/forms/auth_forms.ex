defmodule DopamineWeb.Forms.Identifier do
  @behaviour Ecto.Type
  @spec type() :: :map
  def type, do: :map

  def cast(inp) when is_map(inp) do
    type = Map.get(inp, "type")

    unless type == nil do
      convert_from_type(inp, type)
    else
      :error
    end
  end

  def cast(_), do: :error

  @spec load(any()) :: :error | {:ok, map()}
  def load(data) when is_map(data) do
    {:ok, data}
  end

  def load(_), do: :error

  @spec dump(any()) :: :error | {:ok, map()}
  def dump(data) when is_map(data) do
    {:ok, data}
  end

  def dump(_), do: :error

  defp convert_from_type(data, "m.id.user") do
    # Identifier of type "m.id.user" has just a "user" attribute
    if Map.has_key?(data, "user") do
      {:ok, %{type: "m.id.user", user: data["user"]}}
    else
      :error
    end
  end

  defp convert_from_type(_, _), do: :error
end

defmodule DopamineWeb.Forms.AuthData do
  @behaviour Ecto.Type

  @spec type() :: :map
  def type, do: :map

  @spec cast(any()) :: :error | {:ok, map()}
  def cast(inp) when is_map(inp) do
    with true <- Map.has_key?(inp, "type"),
         type <- inp["type"] do
      convert_from_type(inp, type)
    else
      _ -> :error
    end
  end

  def cast(_) do
    :error
  end

  @spec load(map()) :: {:ok, map()}
  def load(data) when is_map(data) do
    {:ok, data}
  end

  def dump(data) when is_map(data) do
    {:ok, data}
  end

  def dump(_), do: :error

  defp convert_from_type(inp, "m.login.password") do
    map = %{}
    types = %{type: :string, identifier: DopamineWeb.Forms.Identifier, password: :string}

    changeset =
      {map, types}
      |> Ecto.Changeset.cast(inp, [:identifier, :type, :password])
      |> Ecto.Changeset.validate_required([:type, :password])

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} -> {:ok, data}
      {:error, _err} -> :error
    end
  end

  defp convert_from_type(_, _), do: :error
end

defmodule DopamineWeb.Forms.RegisterForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:bind_email, :boolean)
    field(:username, :string)
    field(:password, :string)
    field(:device_id, :string)
    field(:initial_device_display_name, :string)
    field(:inhibit_login, :boolean)
    field(:auth, DopamineWeb.Forms.AuthData)
  end

  def validate(data) do
    cs =
      %__MODULE__{}
      |> changeset(data)

    if cs.valid? do
      {:ok, apply_changes(cs)}
    else
      IO.inspect(cs)
      # TODO - proper error code
      {:error, :form}
    end
  end

  def changeset(struct, data) do
    struct
    |> cast(data, [:username, :password, :device_id, :auth])
  end
end
