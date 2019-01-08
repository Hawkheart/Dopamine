defmodule Dopamine.Application do
  @moduledoc """
  The Dopamine Application Service.

  The dopamine system business domain lives in this application.

  Exposes API to clients such as the `DopamineWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link(
      [
        Dopamine.Repo,
        {DynamicSupervisor, strategy: :one_for_one, name: Dopamine.MatrixSupervisor},
        {Registry, keys: :unique, name: Dopamine.MatrixRegistry}
      ],
      strategy: :one_for_one,
      name: Dopamine.Supervisor
    )
  end
end
