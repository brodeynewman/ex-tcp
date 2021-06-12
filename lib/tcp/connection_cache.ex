defmodule Tcp.ConnectionCache do
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

  def handle_call({:register, socket}, _, %{clients: clients, users: _users} = state) do
    case Map.get(clients, socket) do
      nil ->
        IO.inspect("NO USER FOUND")

        {:ok, pid} =
          DynamicSupervisor.start_child(
            Tcp.DynamicSupervisor,
            {Tcp.ConnectionServer, {socket}}
          )

        IO.inspect("SERVER CREATED")
        IO.inspect(pid)

        {:reply, pid, %{state | clients: Map.put(clients, socket, pid)}}

      pid ->
        IO.inspect("FOUND")
        {:reply, pid, state}
    end
  end
end
