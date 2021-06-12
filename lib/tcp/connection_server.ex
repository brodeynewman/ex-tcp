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
        {:user_joined, all_users},
        %{pid: pid, parent: _parent, initialized: _init, name: name} = state
      ) do
    :gen_tcp.send(pid, get_welcome_message(all_users, name))

    {:noreply, state}
  end

  def handle_cast(
        {:user_left, left_user, _all_users},
        %{pid: pid, parent: _parent, initialized: _init, name: _name} = state
      ) do
        :gen_tcp.send(pid, "#{left_user} has left the chat." <> @nl)

    {:noreply, state}
  end

  def handle_cast(
        {:new_user_joined, new_user, _all_users},
        %{pid: pid, parent: _parent, initialized: _init, name: _} = state
      ) do
    :gen_tcp.send(pid, "#{new_user} has joined the chat." <> @nl)

    {:noreply, state}
  end

  def handle_cast(
        {:new_message, from_user, message},
        %{pid: pid, parent: _parent, initialized: _init, name: _} = state
      ) do
    :gen_tcp.send(pid, ts() <> "#{from_user} - #{message}")

    {:noreply, state}
  end

  def handle_cast({:send, packet}, %{pid: pid, parent: _parent, initialized: _init} = state) do
    :gen_tcp.send(pid, packet)

    {:noreply, state}
  end

  defp send(packet) do
    GenServer.cast(self(), {:send, packet})
  end

  def handle_info({:tcp, _socket, msg}, %{initialized: true, parent: parent_pid, pid: _, name: name} = state) do
    # handle message once user is initialized
    GenServer.cast(parent_pid, {:new_message, msg, name})

    {:noreply, state}
  end

  def handle_info(
        {:tcp, _, name},
        %{initialized: false, parent: parent, pid: _, name: nil} = state
      ) do
    GenServer.cast(parent, {:user_joined, name, self()})

    # first message is always the name of the user, so we can flip our initialized flag
    {:noreply, %{state | initialized: true, name: name}}
  end

  def handle_info({:tcp_closed, pid}, %{initialized: true, parent: parent_id, pid: _, name: name} = state) do
    GenServer.cast(parent_id, {:user_left, pid, name})

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _pid}, %{initialized: false, parent: _, pid: _, name: _} = state) do
    # Do nothing if user disconnects before supplying a username. No one cares about the anonymous man.
    {:noreply, state}
  end

  defp ts() do
    "[#{Time.truncate(Time.utc_now(), :second)}] "
  end
end
