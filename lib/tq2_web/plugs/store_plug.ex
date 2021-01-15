defmodule Tq2Web.StorePlug do
  import Plug.Conn, only: [assign: 3]

  alias Tq2.Shops

  def fetch_store(%{params: %{"slug" => slug}} = conn, _opts) when is_binary(slug) do
    try do
      store = Shops.get_store!(slug)

      conn |> assign(:current_store, store)
    rescue
      Ecto.NoResultsError -> Tq2Web.ErrorView.render_404(conn)
    end
  end

  def fetch_store(conn, _opts), do: conn
end
