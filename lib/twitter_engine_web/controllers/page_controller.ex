defmodule TwitterEngineWeb.PageController do
  use TwitterEngineWeb, :controller

  alias TwitterEngine.Server.Models.User
  alias TwitterEngine.Server.Models.Tweet
  alias TwitterEngine.Server.Models.Hashtag

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def join_p(u) do
    {:ok, username} = User.new(%{username: u})

    TwitterEngine.Server.broadcast(%{
      "event": "new_user",
      "subject": username
    })
  end

  def create_tweet_p(user, tweet) do
    Tweet.new(%{content: tweet}, user)
  end

  def join(conn, params) do
    username = Map.get(params, "username")
    {:ok, username} = User.new(%{username: username})

    TwitterEngine.Server.broadcast(%{
      "event": "new_user",
      "subject": username
    })

    json(conn, %{username: username})
  end

  def create_tweet(conn, params) do
    user = Map.get(params, "user")
    tweet = Map.get(params, "tweet")
    {:ok, tweet_id} = Tweet.new(%{content: tweet}, user)
    json(conn, %{id: tweet_id, content: tweet})
  end

  def subscribe_to_user(conn, params) do
    user_to_subscribe_to = Map.get(params, "user_to_subscribe_to")
    user = Map.get(params, "user")
    User.add_subscriber(user_to_subscribe_to, user)
    json(conn, %{status: "success"})
  end

  def subscribe_to_hashtag(conn, params) do
    hashtag = Map.get(params, "hashtag")
    user = Map.get(params, "user")
    Hashtag.add_subscriber(hashtag, user)
    json(conn, %{status: "success"})
  end

  def retweet(conn, params) do
    content = Map.get(params, "content")
    content = "RT: " <> content

    user = Map.get(params, "user")

    Tweet.new(%{content: content}, user)
    json(conn, %{content: content})
  end

  def search(conn, params) do
    query = Map.get(params, "query")

    records = if String.starts_with? query, "#" do
      TwitterEngine.Server.DB.query(:tweets, :hashtags, query)
    else
      TwitterEngine.Server.DB.query(:tweets, :mentions, String.slice(query, 1..-1))
      |> Map.values
    end

    json(conn, %{records: records})
  end
end
