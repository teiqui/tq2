defmodule Tq2Web.VisitPlug do
  import Plug.Conn

  alias Tq2.Analytics

  def track_visit(%{params: %{"slug" => slug}} = conn, _opts) do
    case get_session(conn, :visit_id) do
      nil ->
        register_visit(conn, slug)

      visit_id ->
        track_view(conn, slug, visit_id)
    end
  end

  defp register_visit(conn, slug) do
    {:ok, view} =
      Analytics.create_view(%{
        path: "/#{Enum.join(conn.path_info, "/")}",
        visit: %{
          slug: slug,
          token: get_session(conn, :token),
          referral_token: conn.params["referral"],
          utm_source: conn.params["utm_source"],
          data: %{
            ip: conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
          }
        }
      })

    conn
    |> put_session(:visit_id, view.visit_id)
    |> put_session(:visit_timestamp, DateTime.utc_now() |> DateTime.to_unix())
  end

  defp track_view(conn, slug, visit_id) do
    now = DateTime.utc_now()

    expires =
      conn
      |> get_session(:visit_timestamp)
      |> DateTime.from_unix!()
      |> Timex.shift(hours: 4)

    case DateTime.compare(now, expires) do
      :gt ->
        register_visit(conn, slug)

      _ ->
        {:ok, _view} =
          Analytics.create_view(%{
            path: "/#{Enum.join(conn.path_info, "/")}",
            visit_id: visit_id
          })

        conn
    end
  end
end
