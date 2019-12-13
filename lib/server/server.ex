require Logger

defmodule TwitterEngine.Server do
  use GenServer

  alias TwitterEngine.Server.Models.User, as: User
  alias TwitterEngine.Server.Models.Tweet, as: Tweet
  alias TwitterEngine.Server.Models.Hashtag, as: Hashtag

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: {:global, :server})
  end

  @impl true
  def init(_init_arg) do
    {:ok, nil}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:set_state, new_state}, _from, _state) do
    {:reply, :ok, new_state}
  end

  # Implement Server APIs

  @impl true
  def handle_call({:create_account, user}, _from, state) do
    {:ok, user_id} = User.new(user)
    {:reply, {:ok, user_id}, state}
  end

  @impl true
  def handle_call({:delete_account, user}, _from, state) do
    :ok = User.delete(user)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:query, table}, _from, state) do
    records = TwitterEngine.Server.DB.get_all(table)
    {:reply, records, state}
  end

  @impl true
  def handle_call({:query, table, key, value}, _from, state) do
    records = TwitterEngine.Server.DB.query(table, key, value)
    {:reply, records, state}
  end

  @impl true
  def handle_call(:get_db_stats, _from, state) do
    db_stats = TwitterEngine.Server.DB.get_stats()
    {:reply, db_stats, state}
  end

  # create a new tweet for a user
  @impl true
  def handle_cast({:create_tweet, tweet, user_id}, state) do
    {:ok, _tweet_id} = Tweet.new(tweet, user_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:retweet, tweet_to_retweet, user_id}, state) do
    {:ok, _tweet_id} = Tweet.retweet(tweet_to_retweet, user_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe_to_user, user_to_subscribe_to, user_id}, state) do
    User.add_subscriber(user_to_subscribe_to, user_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe_to_hashtag, hashtag_to_subscribe_to, user_id}, state) do
    Hashtag.add_subscriber(hashtag_to_subscribe_to, user_id)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_notification, user, notification}, state) do
    :global.send :client, {:notification, notification, user}
    TwitterEngine.Server.DB.increment_stats("notifications_sent")
    {:noreply, state}
  end

  def broadcast(payload) do
    TwitterEngineWeb.Endpoint.broadcast! "room:lobby", "notification", payload
  end

  def broadcast_to_one(user, payload) do
    payload = Map.put(payload, "show_for", user)
    TwitterEngineWeb.Endpoint.broadcast! "room:lobby", "feed", payload
  end
end
