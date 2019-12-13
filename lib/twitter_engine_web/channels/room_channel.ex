defmodule TwitterEngineWeb.RoomChannel do
  use TwitterEngineWeb, :channel

  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("start_simulation", payload, socket) do
    num_users = "#{Map.get(payload, "users")}" |> String.to_integer
    num_requests = "#{Map.get(payload, "requests")}" |> String.to_integer

    IO.puts "Starting simulation with #{num_users} users and #{num_requests} requests"
    TwitterEngine.Client.run_websocket_simulation(num_users, num_requests)

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
