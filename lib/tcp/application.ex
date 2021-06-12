defmodule Tcp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Tcp.ConnectionProxy, 8080},
      {Tcp.ConnectionManager, name: Tcp.ConnectionManager},
      {DynamicSupervisor, strategy: :one_for_one, name: Tcp.DynamicSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Tcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
