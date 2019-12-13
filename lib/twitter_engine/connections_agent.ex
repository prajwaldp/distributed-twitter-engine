defmodule TwitterEngineWeb.ConnectionsAgent do
  use Agent

  @doc """
  Starts a new state maintainer.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Gets a value from the `WebSocketConnections` by `key`.
  """
  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `WebSocketConnections`.
  """
  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end