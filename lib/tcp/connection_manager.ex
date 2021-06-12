defmodule Tcp.ConnectionManager do
  require Logger
  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    Logger.debug("#{__MODULE__} cache started. pid: #{inspect(self())}")

    {:ok, %{clients: %{}, users: %{}}}
  end

  def register(socket) do
    Logger.debug("Cache received tcp sock from #{inspect(socket)}")

    GenServer.call(__MODULE__, {:register, socket})
  end

  def handle_cast({:user_joined, name, child_pid}, %{clients: _, users: users} = state) do
    Logger.debug("Username collected: #{name} for child process: #{inspect(child_pid)}")

    new_users = Map.put(users, name, child_pid)

    # hand our child process all of the user names WITHOUT our new user
    GenServer.cast(child_pid, {:user_joined, Map.keys(users)})

    {:noreply, %{state | users: new_users}}
  end

  def handle_call({:register, socket}, _, %{clients: clients, users: _users} = state) do
    case Map.get(clients, socket) do
      nil ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            Tcp.DynamicSupervisor,
            {Tcp.ConnectionServer, {socket, self()}}
          )

        {:reply, pid, %{state | clients: Map.put(clients, socket, pid)}}

      _ ->
        {:noreply, state}
    end
  end
end
