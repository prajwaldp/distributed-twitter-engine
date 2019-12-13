defmodule TwitterEngine.Server.Models.TweetTest do
  use ExUnit.Case
  doctest TwitterEngine.Server.Models.Tweet

  alias TwitterEngine.Server.Models.Tweet, as: Tweet
  alias TwitterEngine.Server.Models.User, as: User

  test "initially there are no tweets" do
    assert Tweet.get_all() == %{}
  end

  test "create tweet adds a tweet to the tweets table" do
    {:ok, user_id} = User.new(%{username: "user1"})
    tweet = %{content: "This is a test tweet"}

    {:ok, tweet_id} = Tweet.new(tweet, user_id)

    tweets = Tweet.get_all()
    assert Enum.member?(Map.keys(tweets), tweet_id)

    reset_db()
  end

  test "create tweet fails if user does not exist" do
    user_id = "user1"
    tweet = %{content: "This is a test tweet"}

    {status, msg} = Tweet.new(tweet, user_id)
    assert status == :error
    assert msg == "User #{user_id} does not exist"

    reset_db()
  end

  test "create tweet adds tweet to user's tweets list" do
    {:ok, user_id} = User.new(%{username: "user1"})
    tweet = %{content: "This is a test tweet"}

    {:ok, tweet_id} = Tweet.new(tweet, user_id)

    user = User.get(user_id)
    user_tweets = Map.get(user, :tweets)
    assert Enum.member?(user_tweets, tweet_id)

    reset_db()
  end

  test "querying tweet with a hashtag returns all tweets with that hashtag" do
    {:ok, user_id} = User.new(%{username: "user"})

    # Create two tweets
    tweet1 = %{content: "This is a test tweet #SampleHashtag"}
    Tweet.new(tweet1, user_id)

    tweet2 = %{content: "This is a test tweet #SampleHashtag"}
    Tweet.new(tweet2, user_id)

    tweet3 = %{content: "This is a test tweet #SampleHashtag2"}
    Tweet.new(tweet3, user_id)

    tweets = TwitterEngine.Server.DB.query(:tweets, :hashtags, "#SampleHashtag")
    tweet_contents = Enum.map(tweets, fn t ->
      Map.get(t, :content)
    end)

    assert Enum.member?(tweet_contents, "This is a test tweet #SampleHashtag")
    assert Enum.member?(tweet_contents, "This is a test tweet #SampleHashtag")
    assert not Enum.member?(tweet_contents, "This is a test tweet #SampleHashtag2")

    reset_db()
  end

  test "querying tweet with a mention returns all tweets with that mention" do
    {:ok, user_id} = User.new(%{username: "user"})
    User.new(%{username: "user1"})
    User.new(%{username: "user2"})

    tweet1 = %{content: "This is a test tweet @user1"}
    Tweet.new(tweet1, user_id)

    tweet2 = %{content: "This is a test tweet @user1"}
    Tweet.new(tweet2, user_id)

    tweet3 = %{content: "This is a test tweet @user2"}
    Tweet.new(tweet3, user_id)

    tweets = TwitterEngine.Server.DB.query(:tweets, :mentions, "user1")

    tweet_contents = Enum.map(tweets, fn {_, t} ->
      Map.get(t, :content)
    end)

    assert Enum.member?(tweet_contents, "This is a test tweet @user1")
    assert Enum.member?(tweet_contents, "This is a test tweet @user1")
    assert not Enum.member?(tweet_contents, "This is a test tweet @user2")

    reset_db()
  end

  test "retweeting a tweet creates a new tweet with the prefix RT:" do
    User.new(%{username: "user1"})
    User.new(%{username: "user2"})

    tweet = %{content: "This is a test tweet @user1"}
    {:ok, original_tweet_id} = Tweet.new(tweet, "user1")
    {:ok, retweeted_tweet_id} = Tweet.retweet(original_tweet_id, "user2")

    retweet_tweet = Map.get(Tweet.get(retweeted_tweet_id), :content)

    assert retweet_tweet == "RT: This is a test tweet @user1"

    reset_db()
  end

  # Should be called after every test that alters the DB
  defp reset_db do
    TwitterEngine.Server.DB.reset()
  end
end
