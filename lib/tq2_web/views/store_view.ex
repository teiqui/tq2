defmodule Tq2Web.StoreView do
  use Tq2Web, :view
  use Scrivener.HTML

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
end
