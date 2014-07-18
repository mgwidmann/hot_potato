defmodule HotPotato.PotatoWorker do
  use GenServer

  #
  # Public API
  #

  @doc """
    Gets the leader pid in the mesh. This process starts the game.
  """
  def leader, do: :global.whereis_name(__MODULE__)

  @doc """
    Gets the locally registered worker process. Watch out for the hot potato!
  """
  def local_worker, do: :erlang.whereis(:player)

  @doc """
    Gets either the leader (if you are the leader) or the locally registered player.
  """
  def player do 
    if local_worker == :undefined do
      leader
    else
      local_worker
    end
  end

  @doc """
    Asks the leader for the list of the players. All processes can access this information to pick a random user to pass the hot potato.
  """
  def players do
    GenServer.call(leader, :players)
  end

  @doc """
  """
  def start do
    GenServer.cast(leader, :start)
  end

  #
  # GenServer API calls
  #

  @doc """
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  """
  def init(_) do
    case :global.register_name(__MODULE__, self, &:global.notify_all_name/3) do
      :no  ->
        :erlang.register(:player, self)
        Process.link(leader)
        IO.puts "I'm just a regular player..."
        GenServer.cast(leader, {:register, self, node})
        {:ok, %{role: :player} }
      :yes ->
        IO.puts "Im Leader!"
        {:ok, %{role: :leader, players: [{node, self}]} }
    end
  end

  @doc """
  """
  def handle_call(:players, from, state) do
    {:reply, state.players, state}
  end

  @doc """
  """
  def handle_cast({:register, from, n}, state) do
    {:noreply, %{ state | players: state.players ++ [{n, from}] } }
  end

  def handle_cast(:start, state) do
    handle_hot_potato {node, self}, state.players
    {:noreply, state}
  end

  def handle_cast(:hot_potato, state) do
    IO.puts "Got the hot potato! Ouch... its HOT!"
    all_players = if self == leader do
                         state.players
                       else
                         players
                       end
    last_to_handle = self
    random_player = pick_random_player(last_to_handle, all_players)
    spawn_link fn ->
      handle_hot_potato random_player, all_players
    end
    {:noreply, state}
  end

  defp handle_hot_potato({name, player}, all_players) do
    (:random.uniform(5) * 1000) |> :timer.sleep
    IO.puts "Passed hot potato to #{node_name(name)}!"
    GenServer.cast(player, :hot_potato)
  end

  defp node_name(name) do
    name |> to_string |> String.split("@") |> Enum.at(0)
  end

  defp pick_random_player last_to_handle, all_players do
    s = all_players |> Enum.filter(fn({_n,pid})-> pid != last_to_handle end)
    max_random_player = s |> Enum.count
    random_player = :random.uniform(max_random_player) - 1
    {name, player} = Enum.at(s, random_player)
  end

  @doc """
  """
  def handle_info({:global_name_conflict, name, _other_pid}, state) do
    {:stop, {:global_name_conflict, name}, state}
  end

end