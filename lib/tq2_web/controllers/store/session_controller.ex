defmodule Tq2Web.Store.SessionController do
  use Tq2Web, :controller

  @doc """
  Controller to manage session for live views.
  """

  def dismiss_price_info(conn, _params) do
    conn = put_session(conn, :hide_price_info, true)

    json(conn, %{})
  end
end
