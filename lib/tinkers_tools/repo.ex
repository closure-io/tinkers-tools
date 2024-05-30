defmodule TinkersTools.Repo do
  use Ecto.Repo,
    otp_app: :tinkers_tools,
    adapter: Ecto.Adapters.Postgres
end
