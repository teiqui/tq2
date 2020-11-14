defmodule Tq2Web.ItemView do
  use Tq2Web, :view
  use Scrivener.HTML

  alias Tq2.Inventories.Item

  @visibilities %{
    dgettext("items", "Visible") => "visible",
    dgettext("items", "Hidden") => "hidden"
  }

  def link_to_show(conn, item) do
    icon_link(
      "eye-fill",
      title: dgettext("items", "Show"),
      to: Routes.item_path(conn, :show, item),
      class: "ml-2"
    )
  end

  def link_to_edit(conn, item) do
    icon_link(
      "pencil-fill",
      title: dgettext("items", "Edit"),
      to: Routes.item_path(conn, :edit, item),
      class: "ml-2"
    )
  end

  def link_to_delete(conn, item) do
    icon_link(
      "trash2-fill",
      title: dgettext("items", "Delete"),
      to: Routes.item_path(conn, :delete, item),
      method: :delete,
      data: [confirm: dgettext("items", "Are you sure?")],
      class: "ml-2 text-danger"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, item) do
    hidden_input(form, :lock_version, value: item.lock_version)
  end

  def submit_button(item) do
    item
    |> submit_label()
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  def categories(account) do
    account
    |> Tq2.Inventories.list_categories()
    |> Enum.map(&[key: &1.name, value: &1.id])
  end

  def visibilities do
    @visibilities
  end

  def visibility(item) do
    visibilities = invert(@visibilities)

    visibilities[item.visibility]
  end

  def category(nil), do: dgettext("items", "None")
  def category(category), do: category.name

  def money(money) do
    Money.to_string(money, symbol: true)
  end

  def image(%Item{image: nil}), do: nil

  def image(%Item{image: image} = item) do
    url = Tq2.ImageUploader.url({image, item}, :thumb)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "120",
      height: "55",
      loading: "lazy",
      alt: item.name,
      class: "img-thumbnail mb-1"
    )
  end

  defp submit_label(nil), do: dgettext("items", "Create")
  defp submit_label(_), do: dgettext("items", "Update")

  defp invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end
end
