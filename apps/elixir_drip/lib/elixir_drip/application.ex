defmodule ElixirDrip.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Supervisor.start_link(
          [
            supervisor(ElixirDrip.Repo, []),
            supervisor(ElixirDrip.Storage.Supervisors.CacheSupervisor, [], name: CacheSupervisor)
          ],
          strategy: :one_for_one,
          name: ElixirDrip.Supervisor
          )
  end
end
