defmodule Tcp.ConnectionProxy do
  require Logger
  use GenServer

  alias Tcp.ConnectionManager

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, [])
  end

  def init(port) do
    GenServer.cast(self(), :tunnel)

    :gen_tcp.listen(
      port,
      [:binary, packet: :line, active: true, reuseaddr: true]
    )
  end

  defp start_tunnel(socket) do
    {:ok, incoming_sock} = :gen_tcp.accept(socket)

    # register our newly received tcp connection in our cache
    # and use the pid to proxy tcp packets to
    cache_pid = ConnectionManager.register(incoming_sock)

    ## forward incoming tcp connections to our connection cache
    :gen_tcp.controlling_process(incoming_sock, cache_pid)

    start_tunnel(socket)
  end

  def handle_cast(:tunnel, socket) do
    start_tunnel(socket)

    {:noreply, socket}
  end
end
