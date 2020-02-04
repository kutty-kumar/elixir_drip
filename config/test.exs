use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_drip_web, ElixirDripWeb.Endpoint,
  http: [port: 4002],
  server: false

# Configure your database
config :elixir_drip, ElixirDrip.Repo,
  username: "root",
  password: "",
  database: "elixir_drip_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
