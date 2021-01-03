defmodule Tq2Web.StoreView do
  use Tq2Web, :view
  use Scrivener.HTML

  defp public_store_link(store) do
    url = store_uri() |> Routes.counter_url(:index, store)

    link(url, to: url) |> safe_to_string()
  end

  defp store_slug_hint do
    dgettext(
      "stores",
      "This is part of the store address, you can only use letters, underscores and numbers, don't use spaces!"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, store) do
    hidden_input(form, :lock_version, value: store.lock_version)
  end

  def submit_button(store) do
    store
    |> submit_label()
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  defp submit_label(nil), do: dgettext("stores", "Create")
  defp submit_label(_), do: dgettext("stores", "Update")

  defp store_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :store_subdomain), url_config[:host]], ".")
    }
  end
end
