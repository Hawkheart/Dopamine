defmodule Dopamine.PubSub do
  def send_to_user(username, message) do
    Registry.dispatch(__MODULE__, username, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end

  def subscribe_to_user(username) do
    Registry.register(__MODULE__, username, self())
  end
end
