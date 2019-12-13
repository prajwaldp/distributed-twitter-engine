defmodule TwitterEngine.Server.Models.UserTest do
  use ExUnit.Case
  doctest TwitterEngine.Server.Models.User

  alias TwitterEngine.Server.Models.User, as: User

  test "initially there are no users" do
    assert User.get_all() == %{}
  end

  test "new user adds a user to the database state" do
    user = %{username: "user1"}
    User.new(user)
    users = User.get_all()

    assert Enum.member?(Map.keys(users), "user1")

    reset_db()
  end

  test "delete user removes the user from the database state" do
    user = %{username: "user1"}
    User.new(user)
    users = User.get_all()

    assert Enum.member?(Map.keys(users), "user1")

    User.delete(user)
    users = User.get_all()

    assert length(Map.keys(users)) == 0
    assert not Enum.member?(Map.keys(users), "user1")

    reset_db()
  end

  test "subscribing to a user adds the subscriber to the subscribers list of the user" do
    user1 = %{username: "user1"}
    User.new(user1)

    user2 = %{username: "user2"}
    User.new(user2)

    user3 = %{username: "user3"}
    User.new(user3)

    User.add_subscriber("user1", "user2")
    user1_details = User.get("user1")

    assert Enum.member?(Map.get(user1_details, :subscribers), "user2")
    assert not Enum.member?(Map.get(user1_details, :subscribers), "user3")

    reset_db()
  end

  # Should be called after every test that alters the DB
  defp reset_db do
    TwitterEngine.Server.DB.reset()
  end
end
