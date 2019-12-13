defmodule TwitterEngine.Client.Helper do
  def random_tweet do
    1..100
      |> Enum.map(fn i -> "Sample tweet #{i}" end)
      |> Enum.random
  end

  def random_hashtag do
    1..100
      |> Enum.map(fn i -> "#Hashtag#{i}" end)
      |> Enum.random
  end
end