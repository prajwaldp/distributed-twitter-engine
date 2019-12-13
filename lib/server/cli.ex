defmodule TwitterEngine.Server.CLI do

  @hostname :"server@127.0.0.1"
  @cookie :secret

  def main do

    Node.start(@hostname)
    Node.set_cookie(Node.self(), @cookie)

    TwitterEngine.Server.Supervisor.start()

    :timer.sleep 100
    IO.gets "Press [Enter] to exit..."
  end
end
