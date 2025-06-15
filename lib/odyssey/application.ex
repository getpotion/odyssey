defmodule Odyssey.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OdysseyWeb.Telemetry,
      Odyssey.Repo,
      {DNSCluster, query: Application.get_env(:odyssey, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Odyssey.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Odyssey.Finch},
      # Start a worker by calling: Odyssey.Worker.start_link(arg)
      # {Odyssey.Worker, arg},
      # Start to serve requests, typically the last entry
      OdysseyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Odyssey.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OdysseyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
