defmodule Tq2Web.HealthController do
  use Tq2Web, :controller

  def index(conn, _params) do
    send_resp(conn, :ok, "")
  end
end
