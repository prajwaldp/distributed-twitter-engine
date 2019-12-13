require Logger

defmodule TwitterEngine.Client.CLI do

  @hostname :"client@127.0.0.1"
  @cookie :secret
  @server_hostname :"server@127.0.0.1"

  def main do
    connect_to_server()

    args = System.argv()

    if length(args) != 2 do
      IO.puts ">> Usage: mix run client.exs [num_users] [num_messages]"
      exit :shutdown
    end

    num_users = Enum.at(args, 0) |> String.to_integer
    num_messages = Enum.at(args, 1) |> String.to_integer

    TwitterEngine.Client.run_simulation(num_users, num_messages)
  end

  def connect_to_server do
    Node.start(@hostname)
    Node.set_cookie(Node.self(), @cookie)

    # Test the connection to the server
    unless Node.connect(@server_hostname)  == true do
      Logger.error "Cannot connect to #{inspect @server_hostname}. Make sure it's running!"
      exit :shutdown
    end

    :global.sync()

    unless GenServer.call({:global, :server}, :ping) == :pong do
      Logger.error "Cannot ping #{inspect @server_hostname}. Make sure it's running!"
      exit :shutdown
    end

    IO.puts "Successfully connected to #{Enum.at(Node.list, 0)}"
  end
end