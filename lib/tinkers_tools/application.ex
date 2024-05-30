defmodule TinkersTools.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TinkersToolsWeb.Telemetry,
      # Start the Ecto repository
      TinkersTools.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TinkersTools.PubSub},
      # Start Finch
      {Finch, name: TinkersTools.Finch},
      # Start the Endpoint (http/https)
      TinkersToolsWeb.Endpoint
      # Start a worker by calling: TinkersTools.Worker.start_link(arg)
      # {TinkersTools.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TinkersTools.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TinkersToolsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
