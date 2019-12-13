defmodule TwitterEngine.Repo do
  use Ecto.Repo,
    otp_app: :twitter_engine,
    adapter: Ecto.Adapters.Postgres
end
