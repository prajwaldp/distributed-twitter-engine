defmodule TwitterEngine.Server.Models.Tweet do

  alias TwitterEngine.Server.DB, as: DB
  alias TwitterEngine.Server.Models.User, as: User
  alias TwitterEngine.Server.Models.Tweet, as: Tweet
  alias TwitterEngine.Server.Models.Hashtag, as: Hashtag

  @schema %{
    user_id: nil,
    content: "",
    is_archived: false
  }

  def get_all do
    DB.get_all(:tweets)
  end

  def get(id) do
    DB.get(:tweets, id)
  end

  def new(%{content: content}, user_id) do
    if not Enum.member?(Map.keys(User.get_all()), user_id) do
      {:error, "User #{user_id} does not exist"}

    else

      tweet = @schema
      tweet = Map.put(tweet, :user_id, user_id)
      tweet = Map.put(tweet, :content, content)

      # Get tagged users from the tweet content
      mentions =
        String.split(content, " ")
        |> Enum.filter(fn w -> String.at(w, 0) == "@" end)
        |> Enum.map(fn u -> String.trim(u, "@") end)

      # Convert PID strings to PID
      mentions = Enum.map(mentions, fn m ->
        if String.match?(m, ~r/#PID<.*>/) do
          String.trim(m, "#PID") |> to_charlist |> :erlang.list_to_pid
        else
          m
        end
      end)

      tweet = Map.put(tweet, :mentions, mentions)

      tweet_id = TwitterEngine.Server.Helper.random_key()

      {:ok, tweet_id} = DB.add(:tweets, tweet_id, tweet)
      {:ok, _user_id, _tweet_id} = DB.add_relationship(:users, user_id, :tweets, tweet_id)

      # Get hashtags from the tweet content
      String.split(content, " ")
      |> Enum.filter(fn h -> String.at(h, 0) == "#" end)
      |> Enum.each(fn h ->
        unless Hashtag.exist?(h) do
          Hashtag.new(h)

          TwitterEngine.Server.broadcast(%{
            "event": "new_hashtag",
            "subject": h
          })
        end

        Hashtag.add_tweet(h, tweet_id)
      end)

      # Send notifications

      # 1. To all the mentioned users
      Enum.each mentions, fn m ->
        notification = "You were mentioned in the tweet '#{content}' by #{inspect user_id}"
        # GenServer.cast {:global, :server}, {:send_notification, m, notification}

        TwitterEngine.Server.broadcast_to_one m, %{
          event: "tweet_with_mention",
          tweet: %{
            id: "#{inspect tweet_id}",
            content: content,
            user_id: user_id
          }
        }
      end

      # 2. To all the tweeter's subscribers
      subscribers = Map.get User.get(user_id), :subscribers
      Enum.each subscribers, fn s ->
        notification = "User #{inspect user_id} tweeted '#{content}'. You received this message because you follow @#{inspect user_id}"
        # GenServer.cast {:global, :server}, {:send_notification, s, notification}

        TwitterEngine.Server.broadcast_to_one s, %{
          event: "tweet_from_subscribee",
          tweet: %{
            id: "#{inspect tweet_id}",
            content: content,
            user_id: user_id
          }
        }
      end

      # 3. To the tweeter herself/himself
      TwitterEngine.Server.broadcast(%{
        "event": "new_tweet",
        "subject": content
      })

      {:ok, tweet_id}
    end
  end

  def retweet(tweet_to_retweet, user_id) do
    tweet_to_retweet = Tweet.get(tweet_to_retweet)
    content = Map.get(tweet_to_retweet, :content)
    owner = Map.get(tweet_to_retweet, :user_id)

    tweet = %{
      content: "RT: " <> content
    }

    {:ok, tweet_id} = Tweet.new(tweet, user_id)

    # Send a notification to the owner
    # notification = "Your tweet '#{content}' was retweeted by #{inspect user_id}"
    # GenServer.cast {:global, :server}, {:send_notification, owner, notification}

    {:ok, tweet_id}
  end
end
