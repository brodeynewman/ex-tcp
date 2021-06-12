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

  defp notify_user_update(pid, action, updated_user, all_users) do
    GenServer.cast(pid, {action, updated_user, all_users})
  end

  defp broadcast_join(users, user) do
    users
    |> Map.values()
    |> Enum.each(&notify_user_update(&1, :new_user_joined, user, users))
  end

  defp broadcast_leave(users, user) do
    users
    |> Map.values()
    |> Enum.each(&notify_user_update(&1, :user_left, user, users))
  end

  defp broadcast_message(users, from_user, message) do
    users
    |> Map.values()
    |> Enum.each(&GenServer.cast(&1, {:new_message, from_user, message}))
  end

  def handle_cast({:user_left, child_pid, name}, %{clients: clients, users: users} = state) do
    Logger.debug("Username has left: #{name} for child process: #{inspect(child_pid)}")

    updated_users = Map.delete(users, name)

    # tell all child processes that a new user has joined
    broadcast_leave(updated_users, name)

    {:noreply, %{state | users: updated_users, clients: Map.delete(clients, child_pid)}}
  end

  def handle_cast({:user_joined, name, child_pid}, %{clients: _, users: users} = state) do
    Logger.debug("Username collected: #{name} for child process: #{inspect(child_pid)}")

    new_users = Map.put(users, name, child_pid)

    # hand our child process all of the user names WITHOUT our new user
    GenServer.cast(child_pid, {:user_joined, Map.keys(users)})

    # tell all child processes that a new user has joined
    broadcast_join(users, name)

    {:noreply, %{state | users: new_users}}
  end

  def handle_cast({:new_message, msg, from_user}, %{clients: _, users: users} = state) do
    users
    |> Map.delete(from_user)
    |> broadcast_message(from_user, msg)

    {:noreply, state}
  end

  def handle_call({:register, socket}, _, %{clients: clients, users: _users} = state) do
    case Map.get(clients, socket) do
      nil ->
        {:ok, pid} =
          # If no user exists, spin up a new connection server
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
