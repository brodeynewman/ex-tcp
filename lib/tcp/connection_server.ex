defmodule Tcp.ConnectionServer do
  require Logger
  use GenServer

  @nl "\r\n"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def init({socket, parent}) do
    Logger.debug(
      "#{__MODULE__} connection sever dynamically started. pid: #{inspect(self())}, #{
        inspect(socket)
      }"
    )

    Logger.debug("#{__MODULE__} User joined. Asking for name: #{inspect(socket)}")

    send(@nl <> "Welcome to the chat! Please enter your name: ")

    {:ok, %{pid: socket, parent: parent, initialized: false, name: nil}}
  end

  defp get_welcome_message(users, name) when length(users) == 1,
    do: "Hi #{name} you are connected with: #{Enum.join(users, ", ")}" <> @nl

  defp get_welcome_message(users, name) when length(users) < 1,
    do: "Hi #{name} you are currently the only user in the room." <> @nl

  defp get_welcome_message(users, name) when length(users) > 0,
    do:
      "Hi #{name} you are connected with #{length(users)} other user(s): #{Enum.join(users, ", ")}" <>
        @nl

  def handle_cast(
        {:user_joined, users},
        %{pid: pid, parent: _parent, initialized: _init, name: name} = state
      ) do
    :gen_tcp.send(pid, get_welcome_message(users, name))

    {:noreply, state}
  end

  def handle_cast({:send, packet}, %{pid: pid, parent: _parent, initialized: _init} = state) do
    :gen_tcp.send(pid, packet)

    {:noreply, state}
  end

  defp send(packet) do
    GenServer.cast(self(), {:send, packet})
  end

  def handle_info({:tcp, socket, msg}, %{initialized: true, parent: _, pid: _, name: _} = state) do
    {:noreply, state}
  end

  def handle_info(
        {:tcp, _, name},
        %{initialized: false, parent: parent, pid: _, name: nil} = state
      ) do
    # first message is always the name of the user, so we can flip our initialized flag

    GenServer.cast(parent, {:user_joined, name, self()})

    {:noreply, %{state | initialized: true, name: name}}
  end
end
