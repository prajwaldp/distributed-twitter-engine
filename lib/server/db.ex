defmodule TwitterEngine.Server.DB do
  use GenServer

  @schema %{
    users: %{},
    tweets: %{},
    hashtags: %{},
    notifications: %{},
    stats: %{}
  }

  def start_link(db) do
    GenServer.start_link(__MODULE__, db, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    {:ok, @schema}
  end

  # Callbacks

  @impl true
  def handle_call(:reset, _from, _db) do
    increment_stats("db_resets")
    {:reply, :ok, @schema}
  end

  @impl true
  def handle_call(:get, _from, db) do
    increment_stats("db_gets")
    {:reply, db, db}
  end

  @impl true
  def handle_call({:get_all, tablename}, _from, db) do
    increment_stats("#{tablename |> make_singular}_get_alls")
    {:reply, Map.get(db, tablename), db}
  end

  @impl true
  def handle_call({:get, tablename, index}, _from, db) do
    record = Map.get(db, tablename) |> Map.get(index)
    increment_stats("#{tablename |> make_singular}_gets")
    {:reply, record, db}
  end

  @impl true
  def handle_call({:add, tablename, index, record}, _from, db) do
    # Get the current table from the database
    current_table = Map.get(db, tablename)

    # Update the table with the new index and value
    updated_table = Map.put(current_table, index, record)

    # Update the database with the updated table
    updated_db = Map.put(db, tablename, updated_table)

    increment_stats("#{tablename |> make_singular}_additions")

    # Save the updated state in the state
    {:reply, {:ok, index}, updated_db}
  end

  @impl true
  def handle_call({:remove, tablename, index}, _from, db) do
    # Get the current table from the database
    current_table = Map.get(db, tablename)

    # Update the table with the new index and value
    {_, updated_table} = Map.pop(current_table, index)

    # Update the database with the updated table
    updated_db = Map.put(db, tablename, updated_table)

    increment_stats("#{tablename |> make_singular}_removals")

    # Save the updated state in the state
    {:reply, :ok, updated_db}
  end

  @impl true
  def handle_call({:add_relationship, table1, index1, table2, index2}, _from, db) do
    try do
      updated_db = update_in(db, [table1, index1, table2], &([index2] ++ &1))
      increment_stats("#{table1 |> make_singular}_#{table2}_additions")
      {:reply, {:ok, index1, index2}, updated_db}
    rescue
      _ in ArgumentError -> {:reply, {:ok, index1, index2}, db}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, db) do
    {:reply, Map.get(db, :stats), db}
  end

  @impl true
  def handle_cast({:increment_stats, key}, db) do
    stats = Map.get(db, :stats)

    db = if Enum.member? Map.keys(stats), key do
      incremented_val = Map.get(stats, key) + 1
      stats = Map.put(stats, key, incremented_val)
      Map.put(db, :stats, stats)
    else
      stats = Map.put(stats, key, 0)
      Map.put(db, :stats, stats)
    end

    {:noreply, db}
  end

  @doc """
  Gets all items in a table of the database
  """
  def get_all(tablename) do
    GenServer.call __MODULE__, {:get_all, tablename}
  end

  @doc """
  Gets an item with the primary key `index` from the table
  `table` from the database
  """
  def get(tablename, index) do
    GenServer.call __MODULE__, {:get, tablename, index}
  end

  def query(tablename, key, value) do
    if tablename == :tweets && key == :hashtags do

      hashtag = TwitterEngine.Server.DB.get(:hashtags, value)

      if hashtag != nil do

        tweets = TwitterEngine.Server.DB.get_all(:tweets)
        tweet_ids = Map.get hashtag, :tweets

        Enum.map(tweet_ids, fn tweet_id ->
          Map.get(tweets, tweet_id)
        end)

      else
        []
      end

    else

      all_records = GenServer.call __MODULE__, {:get_all, tablename}

      :maps.filter(fn _k, v ->
        list = Map.get(v, key)

        # Convert to string to compare Process IDs
        list = if key == :mentions do
          Enum.map(list, fn i ->
            if String.match?("#{inspect i}", ~r/#PID<.*>/) do
              "#{inspect i}"
            else
              i
            end
          end)
        else
          list
        end

        Enum.member? list, value
      end, all_records)
    end
  end

  @doc """
  Adds a new item to the database.
  The new item is added to the `table` table and has the
  primary key `index` with the value `value`
  """
  def add(tablename, index, value) do
    GenServer.call __MODULE__, {:add, tablename, index, value}
  end

  def remove(tablename, index) do
    GenServer.call __MODULE__, {:remove, tablename, index}
  end

  def add_relationship(table1, index1, table2, index2) do
    GenServer.call __MODULE__, {:add_relationship, table1, index1, table2, index2}
  end

  def reset do
    GenServer.call __MODULE__, :reset
  end

  def increment_stats(key) do
    GenServer.cast __MODULE__, {:increment_stats, key}
  end

  def get_stats do
    GenServer.call __MODULE__, :get_stats
  end

  defp make_singular(s) do
    String.trim_trailing("#{s}", "s")
  end
end
