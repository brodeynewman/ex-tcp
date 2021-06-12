defmodule Tcp.ConnectionServer do
  require Logger
  use GenServer

  @crlf "\r\n"

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, [])
  end

  def init(socket) do
    Logger.debug(
      "#{__MODULE__} connection sever dynamically started. pid: #{inspect(self())}, #{
        inspect(socket)
      }"
    )

    Logger.debug("#{__MODULE__} User joined. Asking for name: #{inspect(socket)}")

    send("Please enter your name" <> @crlf)

    {:ok, %{pid: socket}}
  end

  def handle_cast({:send, packet}, %{pid: {pid}} = state) do
    :gen_tcp.send(pid, packet)

    {:noreply, state}
  end

  defp send(packet) do
    GenServer.cast(self(), {:send, packet})
  end

  def handle_info({:tcp, socket, msg}, state) do
    IO.inspect("RECEIVED MSG")
    IO.inspect(msg)
    IO.inspect(socket)
    IO.inspect(state)

    {:noreply, state}
  end
end
