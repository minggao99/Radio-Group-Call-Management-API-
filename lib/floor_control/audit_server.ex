## Bonus Challenge 4
defmodule FloorControl.AuditServer do
  @moduledoc """
  Keeps historical data of of who had the floor when on what group.
  """

  use GenServer

  ## Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def log_event(event) do
    GenServer.cast(__MODULE__, {:log_event, event})
  end

  def get_logs do
    GenServer.call(__MODULE__, :get_logs)
  end


  ## Server Callbacks
  @impl true
  def init(_args) do
    {:ok, []}
  end

  def handle_cast({:log_event, event}, state) do
    timestamp = DateTime.utc_now() |> DateTime.truncate(:second)
    new_entry = Map.put(event, :timestamp, timestamp)
    {:noreply, [new_entry | state]}
  end

  def handle_call(:get_logs, _from, state) do
    {:reply, Enum.reverse(state), state}
  end
end
