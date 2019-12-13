defmodule TwitterEngine.Server.Models.Hashtag do

  @schema %{
    tweets: [],
    subscribers: []
  }

  def new(hashtag) do
    TwitterEngine.Server.DB.add(:hashtags, hashtag, @schema)
  end

  def get(hashtag) do
    TwitterEngine.Server.DB.get(:hashtags, hashtag)
  end

  def get_all do
    TwitterEngine.Server.DB.get_all(:hashtags)
  end

  def exist?(hashtag) do
    all_hashtags = Map.keys TwitterEngine.Server.DB.get_all(:hashtags)
    Enum.member? all_hashtags, hashtag
  end

  def add_tweet(hashtag, tweet_id) do
    TwitterEngine.Server.DB.add_relationship(:hashtags, hashtag, :tweets, tweet_id)

    # Send a notification to all subscribers
    subscribers = Map.get(TwitterEngine.Server.Models.Hashtag.get(hashtag), :subscribers)

    tweet = TwitterEngine.Server.Models.Tweet.get(tweet_id)
    user_id = Map.get(tweet, :user_id)
    content = Map.get(tweet, :content)

    Enum.each subscribers, fn s ->
      notification = "User #{inspect user_id} tweeted '#{content}'. You received this message because you follow #{hashtag}"
      # GenServer.cast {:global, :server}, {:send_notification, s, notification}

      TwitterEngine.Server.broadcast_to_one s, %{
        event: "tweet_with_hashtag",
        hashtag: hashtag,
        tweet: %{
          id: "#{inspect tweet_id}",
          content: content,
          user_id: user_id
        }
      }
    end
  end

  def add_subscriber(hashtag, user_id) do
    TwitterEngine.Server.DB.add_relationship(:hashtags, hashtag, :subscribers, user_id)
  end

end
