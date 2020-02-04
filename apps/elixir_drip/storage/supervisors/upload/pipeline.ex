defmodule ElixirDrip.Storage.Supervisors.Upload.Pipeline do
  use Supervisor
  require Logger
  alias ElixirDrip.Storage.Pipeline.Encryption

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.debug("#{inspect(self())} Starting the upload pipeline supervisor module.")
    Supervisor.init([worker(Encryption, [], restart: :transient)], strategy: :one_for_one)
  end
end
