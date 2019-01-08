defmodule Dopamine.MatrixRegistry do
  def name(matrix_id) do
    {:via, __MODULE__, {__MODULE__, matrix_id}}
  end

  def lookup(mx_id) when is_binary(mx_id) do
    {:ok, matrix_id} = Dopamine.MatrixID.cast(mx_id)
    lookup(matrix_id)
  end

  def lookup(mx_id = %Dopamine.MatrixID{}) do
    results = Registry.lookup(__MODULE__, mx_id)

    case results do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        start(mx_id)
    end
  end

  defp start("@" <> _) do
    {:error, :unsupported}
  end

  defp start(matrix_id = %Dopamine.MatrixID{sigil: "!"}) do
    import Ecto.Query, only: [from: 2]

    room = Dopamine.Repo.one(from(r in Dopamine.Rooms.Room, where: r.matrix_id == ^matrix_id))

    unless is_nil(room) do
      result =
        DynamicSupervisor.start_child(
          Dopamine.MatrixSupervisor,
          {Dopamine.Rooms.Server, room_id: room.id}
        )

      case result do
        {:ok, pid} -> {:ok, pid}
        {:error, error} -> {:error, error}
        _ -> {:error, :unknown}
      end
    else
      {:error, :not_found}
    end
  end

  def register_name(arg, pid) do
    Registry.register_name(arg, pid)
  end

  def unregister_name(arg) do
    Registry.unregister_name(arg)
  end

  def whereis_name({registry, key}) do
    pid = Registry.whereis_name({registry, key})

    if pid == :undefined do
      {:ok, pid} = start(key)
      pid
    else
      pid
    end
  end

  def send({_registry, key}, msg) do
    {:ok, pid} = lookup(key)
    Kernel.send(pid, msg)
  end
end
