defmodule FloorControl.Router do
  use Plug.Router
  import Plug.Conn
  alias FloorControl.FloorManager

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "FloorControl API is running ")
  end

  get "/groups/:group_id/floor" do
    case FloorManager.get_holder(group_id) do
      {:ok, 200, result} ->
        json(conn, 200, result)

      {:error, status, result} ->
        json(conn, status, result)
    end
  end

  post "/groups/:group_id/floor" do
    case conn.body_params do
      %{"userId" => user_id, "priority" => prio_str} ->
        priority =
          case Integer.parse(prio_str) do
            {num, _} -> num
            :error -> 3
          end

        case FloorManager.obtain_floor(group_id, user_id, priority) do
          {:ok, status, result} -> json(conn, status, result)
          {:error, status, result} -> json(conn, status, result)
        end

      _ ->
        json(conn, 400, %{"error" => "invalid_request"})
    end
  end

  delete "/groups/:group_id/floor/:user_id" do
    case FloorManager.release_floor(group_id, user_id) do
      {:ok, status, result} ->
        json(conn, status, result)

      {:error, status, result} ->
        json(conn, status, result)
    end
  end

  # Audit Endpoint (Bonus Challenge 4)
  get "/audit" do
    logs = FloorControl.AuditServer.get_logs()
    json(conn, 200, %{"audit_log" => logs})
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end


  ## Helper
  defp json(conn, status, map) do
    body = Jason.encode!(map)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end
end
