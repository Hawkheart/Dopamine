defmodule Dopamine.MatrixID do
  @behaviour Ecto.Type
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:sigil, :string)
    field(:localpart, :string)
    field(:domain, :string)
  end

  def changeset(data, attrs) do
    import Ecto.Changeset

    data
    |> cast(attrs, [:sigil, :localpart, :domain])
    |> validate_required([:sigil, :localpart, :domain])
    |> validate_inclusion(:sigil, ["@", "!", "$", "+", "#"])
  end

  @doc ~S"""
  Parses a given Matrix ID (as a string) and returns its parts as a map.
  Does not perform any validation of the input.

  ## Example

      iex> Dopamine.MatrixID.parse("#hello:world")
      %{sigil: "#", localpart: "hello", domain: "world"}
  """
  def parse(input) do
    {sigil, rest} = String.split_at(input, 1)
    [localpart, domain] = String.split(rest, ":", parts: 2)

    %{sigil: sigil, localpart: localpart, domain: domain}
  end

  @doc """
  Generates a new (random) Matrix ID of a given type.
  """
  def generate(type) when is_atom(type) do
    generate(sigil(type))
  end

  def generate(sigil) do
    localpart =
      :crypto.strong_rand_bytes(16)
      |> Base.encode32(case: :lower, padding: false)

    %__MODULE__{
      sigil: sigil,
      localpart: localpart,
      domain: Application.get_env(:dopamine, :hostname)
    }
  end

  def type, do: :string

  def cast(input) when is_binary(input) do
    changeset =
      %__MODULE__{}
      |> changeset(parse(input))

    IO.inspect(changeset)

    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      :error
    end
  end

  def cast(input = %__MODULE__{}) do
    {:ok, input}
  end

  def dump(term) do
    {:ok, to_string(term)}
  end

  def load(term) do
    obj =
      %__MODULE__{}
      |> changeset(parse(term))
      |> Ecto.Changeset.apply_changes()

    {:ok, obj}
  end

  defp sigil(:room), do: "!"
  defp sigil(:alias), do: "#"
  defp sigil(:event), do: "$"
  defp sigil(:user), do: "@"
end

defimpl String.Chars, for: Dopamine.MatrixID do
  def to_string(input) do
    "#{input.sigil}#{input.localpart}:#{input.domain}"
  end
end

defimpl Jason.Encoder, for: Dopamine.MatrixID do
  def encode(struct, opts) do
    Jason.Encode.string(to_string(struct), opts)
  end
end
