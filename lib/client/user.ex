defmodule TwitterEngine.Client.User do
  use GenServer

  @server {:global, :server}

  # Response types
  # 1. Query results
  # 2. Tweets from a user I subscribed to
  # 3. Tweets with a hashtag I subscribed to

  def start_link(_opt) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_info({:set_username, username}, _state) do
    state = %{username: username}
    {:noreply, state}
  end

  @impl true
  def handle_info({:send_random_request, num_requests}, state) do

    username = Map.get(state, :username)

    if num_requests == 0 do

      # IO.puts "Users: #{inspect query_users()}"
      # IO.puts "Tweets: #{inspect query_tweets()}"
      # IO.puts "Hashtags: #{inspect query_hashtags()}"

      # A user sends a delete_account request with a chance of 10%
      case Enum.random 1..10 do
        5 ->
          IO.puts "User #{inspect username} is sending a delete account request"
          delete_account(username)
        _ ->
          nil
      end

      :global.send :client, :done
    else

      # Request types
      # 1. Tweet
      # 2. Tweet with hashtag
      # 3. Tweet with mention
      # 4. Retweet
      # 5. Subscribe to user
      # 6. Subscribe to hashtag
      # 7. Query tweets with specific hashtags
      # 8. Query tweets with specific mentions

      request = Enum.random 1..8

      resp = case request do
        1 -> send_tweet(username)
        2 -> send_tweet_with_hashtag(username)
        3 -> send_tweet_with_mentions(username)
        4 -> retweet(username)
        5 -> subscribe_to_a_user(username)
        6 -> subscribe_to_a_hashtag(username)
        7 -> query_tweets_with_a_hashtag()
        8 -> query_tweets_with_a_mention()
      end

      if resp == :repeat_request do
        Process.send_after self(), {:send_random_request, num_requests}, 10
      else
        Process.send_after self(), {:send_random_request, num_requests - 1}, 10
      end
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:notification, content}, state) do
    username = Map.get(state, :username)
    IO.puts "User #{inspect username} received the notification: #{content}"
    {:noreply, state}
  end

  def create_account(user) do
    params = %{username: user}
    {:ok, user_id} = GenServer.call @server, {:create_account, params}
    {:ok, user_id}
  end

  def delete_account(username) do
    params = %{username: username}
    :ok = GenServer.call @server, {:delete_account, params}
    :ok
  end

  def send_tweet(username) do
    tweet_content = TwitterEngine.Client.Helper.random_tweet()

    tweet = %{
      content: tweet_content
    }

    GenServer.cast @server, {:create_tweet, tweet, username}
  end

  def send_tweet_with_hashtag(username) do
    tweet_content = TwitterEngine.Client.Helper.random_tweet()
    hashtag = TwitterEngine.Client.Helper.random_hashtag()

    tweet = %{
      content: tweet_content <> " " <> hashtag
    }

    GenServer.cast @server, {:create_tweet, tweet, username}
  end

  def send_tweet_with_mentions(username) do
    tweet_content = TwitterEngine.Client.Helper.random_tweet()

    users = query_users()
    if length(Map.keys(users)) > 0 do

      random_users_to_choose = Enum.random(1..Enum.min([length(Map.keys(users)), 3]))

      mentions =
        users
        |> Map.keys()
        |> Enum.take_random(random_users_to_choose)
        |> Enum.map(fn m -> "@#{inspect m}" end)
        |> Enum.join(" ")

      tweet = %{
        content: tweet_content <> " " <> mentions
      }

      GenServer.cast @server, {:create_tweet, tweet, username}
    else
      :repeat_request
    end
  end

  def retweet(username) do
    tweets = query_tweets()

    if length(Map.keys(tweets)) > 0 do
      tweet_to_retweet =
        tweets
        |> Map.keys
        |> Enum.random

      GenServer.cast @server, {:retweet, tweet_to_retweet, username}
    else
      :repeat_request
    end
  end

  def subscribe_to_a_user(username) do
    users = query_users()

    if length(Map.keys(users)) > 0 do

      user_to_subscribe_to =
        users
        |> Map.keys
        |> Enum.random

      GenServer.cast @server, {:subscribe_to_user, user_to_subscribe_to, username}
    else
      :repeat_request
    end
  end

  def subscribe_to_a_hashtag(username) do
    hashtags = query_hashtags()

    if length(Map.keys(hashtags)) > 0 do
      hashtag_to_subscribe_to =
        hashtags
        |> Map.keys
        |> Enum.random

      GenServer.cast @server, {:subscribe_to_hashtag, hashtag_to_subscribe_to, username}
    else
      :repeat_request
    end
  end

  def query_tweets_with_a_hashtag do
    hashtags = query_hashtags()

    if length(Map.keys(hashtags)) > 0 do
      hashtag =
        hashtags
        |> Map.keys
        |> Enum.random

      resp =  GenServer.call @server, {:query, :tweets, :hashtags, hashtag}
      resp =
        resp
        |> Enum.map(fn i -> Map.get(i, :content) end)
        |> Enum.join("\n")

      IO.puts "Queried #{hashtag}. Got the following tweet(s): #{resp}"
    else
      :repeat_request
    end
  end

  def query_tweets_with_a_mention do
    users = query_users()

    if length(Map.keys(users)) > 0 do
      mention =
        users
        |> Map.keys
        |> Enum.random

      resp = GenServer.call @server, {:query, :tweets, :mentions, "#{inspect mention}"}

      resp =
        resp
        |> Map.values
        |> Enum.map(fn i -> Map.get(i, :content) end)
        |> Enum.join("\n")

      IO.puts "Queried @#{inspect mention}. Got the following tweet(s): #{resp}"
    else
      :repeat_request
    end
  end

  def query_users do
    GenServer.call @server, {:query, :users}
  end

  def query_tweets do
    GenServer.call @server, {:query, :tweets}
  end

  def query_hashtags do
    GenServer.call @server, {:query, :hashtags}
  end
end
