defmodule FloorControl.GroupServer do
  @moduledoc """
  Represents a single group process that manages floor (talk right) control.

  Features:
  - Basic floor grant/release
  - Automatic timeout release (Bonus Challenge 1)
  - Retrieve the current floor holder for a specific group (Bonus Challenge 2)
  - Priority-based floor preemption (4 levels) (Bonus Challenge 3)
  """

  use GenServer

  # Can be adjusted to any time
  @timeout_ms 10_000

  ## Client API
  def start_link(group_id) do
    GenServer.start_link(__MODULE__, %{group_id: group_id, holder: nil, timeout_ref: nil}, name: via(group_id))
  end

  def request_floor(group_id, user_id, priority) do
    GenServer.call(via(group_id), {:request_floor, user_id, priority})
  end

  def release_floor(group_id, user_id) do
    GenServer.call(via(group_id), {:release_floor, user_id})
  end

  def get_holder(group_id) do
    GenServer.call(via(group_id), :get_holder)
  end


  ## Server Callback (Bonus Challenge 3)
  @impl true
  def init(state) do
    new_state = Map.put_new(state, :holder_priority, 0)
    {:ok, new_state}
  end

  def handle_call({:request_floor, user_id, priority}, _from, %{holder: nil} = state) do
    ref = Process.send_after(self(), :timeout_release, @timeout_ms)
    new_state = %{state | holder: user_id, holder_priority: priority, timeout_ref: ref}
    FloorControl.AuditServer.log_event(%{
      group: state.group_id,
      user: user_id,
      action: "granted",
      priority: priority
    })
    {:reply, {:ok, :granted, user_id, priority}, new_state}
  end

  def handle_call({:request_floor, user_id, _priority}, _from, %{holder: user_id} = state) do
    {:reply, {:ok, :already_holding, user_id, state.holder_priority}, state}
  end

  def handle_call({:request_floor, user_id, priority}, _from, %{holder: current, holder_priority: current_p} = state) do
    cond do
      priority < current_p ->
        cancel_timer(state.timeout_ref)
        ref = Process.send_after(self(), :timeout_release, @timeout_ms)
        new_state = %{state | holder: user_id, holder_priority: priority, timeout_ref: ref}
        IO.puts("[PREEMPT] #{user_id} (P#{priority}) preempted #{current} (P#{current_p})")
        FloorControl.AuditServer.log_event(%{
          group: state.group_id,
          user: user_id,
          action: "preempted",
          priority: priority
        })
        {:reply, {:ok, :preempted, user_id, priority}, new_state}

      priority >= current_p ->
        {:reply, {:error, :conflict, current, current_p}, state}
    end
  end

  def handle_call({:release_floor, user_id}, _from, %{holder: user_id, timeout_ref: ref} = state) do
    cancel_timer(ref)
    new_state = %{state | holder: nil, holder_priority: nil, timeout_ref: nil}
    FloorControl.AuditServer.log_event(%{
      group: state.group_id,
      user: user_id,
      action: "released",
      priority: state.holder_priority
    })
    {:reply, {:ok, :released}, new_state}
  end

  def handle_call({:release_floor, _user_id}, _from, %{holder: holder} = state) when not is_nil(holder) do
    {:reply, {:error, :forbidden}, state}
  end

  def handle_call({:release_floor, _user_id}, _from, %{holder: nil} = state) do
    {:reply, {:error, :not_found}, state}
  end

  def handle_call(:get_holder, _from, state) do
    {:reply, %{holder: state.holder, priority: state.holder_priority}, state}
  end

  ## Timeout Logic (Bonus Challenge 1+4)
  @impl true
  def handle_info(:timeout_release, state) do
    if state.holder do
      IO.puts("[AUTO RELEASE] Group #{state.group_id} — floor released due to timeout.")
      FloorControl.AuditServer.log_event(%{
        group: state.group_id,
        user: state.holder,
        action: "timeout_released",
        priority: state.holder_priority
      })
      new_state =
        state
        |> Map.put(:holder, nil)
        |> Map.put(:timeout_ref, nil)

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def child_spec(group_id) do
    %{
      id: group_id,
      start: {__MODULE__, :start_link, [group_id]},
      restart: :transient
    }
  end


  ## Helpers
  defp via(group_id), do: {:via, Registry, {FloorControl.Registry, group_id}}

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref), do: Process.cancel_timer(ref)
end
