defmodule TwitterEngine.Server.Models.HashtagTest do
    use ExUnit.Case
    doctest TwitterEngine.Server.Models.Hashtag

    alias TwitterEngine.Server.Models.Tweet, as: Tweet
    alias TwitterEngine.Server.Models.User, as: User
    alias TwitterEngine.Server.Models.Hashtag, as: Hashtag

    test "initially there are no hashtags" do
      assert Hashtag.get_all() == %{}
    end

    test "create tweet with a hashtag adds a hashtag to the hashtags table" do
      {:ok, user_id} = User.new(%{username: "user1"})
      tweet = %{content: "This is a test tweet #SampleHashtag"}

      {:ok, tweet_id} = Tweet.new(tweet, user_id)

      assert Hashtag.exist?("#SampleHashtag")

      hashtag = Hashtag.get("#SampleHashtag")
      assert Enum.member?(Map.get(hashtag, :tweets), tweet_id)

      reset_db()
    end

    test "create tweet with an existing hashtag appends the tweet" do
      {:ok, user_id} = User.new(%{username: "user"})

      # Create two tweets from the same user
      tweet1 = %{content: "This is a test tweet #SampleHashtag"}
      {:ok, tweet1_id} = Tweet.new(tweet1, user_id)

      tweet2 = %{content: "This is a test tweet #SampleHashtag"}
      {:ok, tweet2_id} = Tweet.new(tweet2, user_id)

      hashtag = Hashtag.get("#SampleHashtag")
      assert Enum.member?(Map.get(hashtag, :tweets), tweet1_id)
      assert Enum.member?(Map.get(hashtag, :tweets), tweet2_id)

      reset_db()
    end

    test "subscribing to a hashtag adds the subscriber to the subscribers list of the hashtag" do
      user1 = %{username: "user1"}
      User.new(user1)

      user2 = %{username: "user2"}
      User.new(user2)

      user3 = %{username: "user3"}
      User.new(user3)

      tweet1 = %{content: "This is a test tweet #SampleHashtag"}
      Tweet.new(tweet1, "user1")

      tweet2 = %{content: "This is a test tweet #SampleHashtag2"}
      Tweet.new(tweet2, "user1")

      Hashtag.add_subscriber("#SampleHashtag", "user2")
      hashtag1_details = Hashtag.get("#SampleHashtag")
      hashtag2_details = Hashtag.get("#SampleHashtag2")

      assert Enum.member?(Map.get(hashtag1_details, :subscribers), "user2")
      assert not Enum.member?(Map.get(hashtag2_details, :subscribers), "user2")
      assert not Enum.member?(Map.get(hashtag1_details, :subscribers), "user3")

      reset_db()
    end

    # Should be called after every test that alters the DB
    defp reset_db do
      TwitterEngine.Server.DB.reset()
    end
  end
