defmodule FloorControl.FloorManager do
  @moduledoc """
  Handles all group management and delegates requests to the correct GroupServer.
  - Ensures a group process exists (starts one if not)
  - Delegates floor requests/releases
  """

  alias FloorControl.GroupServer

  ## Public API
  def obtain_floor(group_id, user_id, priority) do
    pid = ensure_group_exists(group_id)

    case GenServer.call(pid, {:request_floor, user_id, priority}) do
      {:ok, :granted, holder, prio} ->
        {:ok, 200, %{"status" => "granted", "holder" => holder, "priority" => prio}}

      {:ok, :already_holding, holder, prio} ->
        {:ok, 200, %{"status" => "already_holding", "holder" => holder, "priority" => prio}}

      {:ok, :preempted, holder, prio} ->
        {:ok, 200, %{"status" => "preempted", "holder" => holder, "priority" => prio}}

      {:error, :conflict, current, current_p} ->
        {:error, 409, %{"status" => "conflict", "holder" => current, "priority" => current_p}}

      other ->
        IO.puts("[WARN] Unexpected response: #{inspect(other)}")
        {:error, 500, %{"error" => "unexpected_response"}}
    end
  end

  def release_floor(group_id, user_id) do
    case Registry.lookup(FloorControl.Registry, group_id) do
      [] ->
        {:error, 404, %{"error" => "group_not_found"}}

      [{pid, _}] ->
        case GenServer.call(pid, {:release_floor, user_id}) do
          {:ok, :released} ->
            {:ok, 200, %{"status" => "released"}}

          {:error, :forbidden} ->
            {:error, 403, %{"error" => "forbidden"}}

          {:error, :not_found} ->
            {:error, 404, %{"error" => "no_holder"}}

          other ->
            IO.puts("[WARN] Unexpected release response: #{inspect(other)}")
            {:error, 500, %{"error" => "unexpected_response"}}
        end
    end
  end

  def get_holder(group_id) do
    case Registry.lookup(FloorControl.Registry, group_id) do
      [] ->
        {:error, 404, %{"error" => "group_not_found"}}

      [{pid, _}] ->
        %{holder: holder, priority: prio} = GenServer.call(pid, :get_holder)
        {:ok, 200, %{"holder" => holder, "priority" => prio}}
    end
  end


  ## Helper
  defp ensure_group_exists(group_id) do
    case Registry.lookup(FloorControl.Registry, group_id) do
      [] ->
        case DynamicSupervisor.start_child(FloorControl.GroupSupervisor, {GroupServer, group_id}) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
          {:error, reason} ->
            IO.puts("[ERROR] Failed to start group #{group_id}: #{inspect(reason)}")
            raise "Failed to start group process"
        end

      [{pid, _}] ->
        pid
    end
  end
end
