defmodule TwitterEngine.Server.Models.User do

  @schema %{
    active: true,
    tweets: [],
    notifications: [],
    subscriptions: [],
    subscribers: [],
  }

  @doc """
  Returns all users
  """
  def get_all do
    TwitterEngine.Server.DB.get_all(:users)
  end

  @doc """
  Returns a user with the id `id`
  """
  def get(id) do
    TwitterEngine.Server.DB.get(:users, id)
  end

  def new(%{username: id}) do
    user = @schema
    TwitterEngine.Server.DB.add(:users, id, user)
  end

  def delete(%{username: id}) do
    TwitterEngine.Server.DB.remove(:users, id)
  end

  def exist?(id) do
    all_users = TwitterEngine.Server.DB.get_all(:users)
    Enum.member? Map.keys(all_users), id
  end

  def add_subscriber(user_id, subscriber) do
    TwitterEngine.Server.DB.add_relationship(:users, user_id, :subscribers, subscriber)
  end
end
