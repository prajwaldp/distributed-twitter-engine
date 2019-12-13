defmodule TwitterEngine.Server.Helper do
  def random_key do
    alphabet = Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9)
    length = 12
    
    Enum.take_random(alphabet, length)
  end 
end