defmodule FloorControl.Application do
  @moduledoc """
  Main application supervisor.
  Starts:
    - Registry: manages all group processes
    - DynamicSupervisor: supervises group processes
    - Plug.Cowboy HTTP server
  """

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: FloorControl.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: FloorControl.GroupSupervisor},
      FloorControl.AuditServer,
      {Plug.Cowboy, scheme: :http, plug: FloorControl.Router, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: FloorControl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
