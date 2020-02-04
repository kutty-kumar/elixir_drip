defmodule ElixirDrip.Repo do
  use Ecto.Repo,
    otp_app: :elixir_drip,
    adapter: Ecto.Adapters.MyXQL
end
