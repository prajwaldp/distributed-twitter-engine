require Logger

defmodule TwitterEngine.Server.Supervisor do

  def start() do
    opts = [strategy: :one_for_one, name: __MODULE__]
    workers = [
      Supervisor.child_spec(TwitterEngine.Server, id: TwitterEngine.Server),
      Supervisor.child_spec(TwitterEngine.Server.DB, id: TwitterEngine.Server.DB)
    ]
    Supervisor.start_link(workers, opts)

    Supervisor.which_children(__MODULE__)
    |> Enum.each(fn {id, pid, :worker, _} ->
      Logger.info "Started #{id} with #{inspect pid}"
    end)

    Node.connect(:"client@127.0.0.1")
    :global.sync()
  end
end
