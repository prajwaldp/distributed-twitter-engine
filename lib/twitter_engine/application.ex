defmodule TwitterEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    # Start the backend server
    TwitterEngine.Server.Supervisor.start()

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      TwitterEngine.Repo,
      # Start the endpoint when the application starts
      TwitterEngineWeb.Endpoint,
      # Starts a worker by calling: TwitterEngine.Worker.start_link(arg)
      # {TwitterEngine.Worker, arg},

      # To keep track of web socket connections by username
      TwitterEngineWeb.ConnectionsAgent
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitterEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterEngineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
