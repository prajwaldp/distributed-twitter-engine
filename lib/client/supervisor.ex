defmodule TwitterEngine.Client.Supervisor do
  def create_users(num_users) do
    users =
      Enum.map(1..num_users, fn i ->
        Supervisor.child_spec(TwitterEngine.Client.User, id: i)
      end)

    opts = [strategy: :one_for_one, name: TwitterEngine.Client.Supervisor]
    Supervisor.start_link(users, opts)
  end
end
