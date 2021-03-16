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

  def visibility(item) do
    visibilities = invert(@visibilities)

    visibilities[item.visibility]
  end

  def category(nil), do: dgettext("items", "None")
  def category(category), do: category.name

  def money(money) do
    Money.to_string(money, symbol: true)
  end

  def image(%Item{image: nil} = item) do
    ~E"""
      <svg class="rounded mb-1"
           viewBox="0 0 150 150"
           width="150"
           height="150"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= item.name %>">
        <g>
          <title><%= item.name %></title>
          <rect width="150" height="150" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(item.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  def image(%Item{image: image} = item) do
    url = Tq2.ImageUploader.url({image, item}, :thumb)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "150",
      height: "150",
      loading: "lazy",
      alt: item.name,
      class: "rounded mb-1"
    )
  end

  defp invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end

  defp link_to_new_item(conn) do
    content = link_to_new_item_content(conn)
    path = link_to_new_item_path(conn)

    link(content, to: path, class: link_to_new_item_classes(conn))
  end

  defp link_to_new_item_path(%{params: %{"tour" => _}} = conn) do
    Routes.item_path(conn, :new, tour: "new_item")
  end

  defp link_to_new_item_path(conn) do
    Routes.item_path(conn, :new)
  end

  defp link_to_new_item_content(%{params: %{"tour" => _}}) do
    ~E"""
      + <%= dgettext("items", "Add item") %>

      <span class="tour-pointer d-block h1 text-info-dark mt-1 mb-0">
        <i class="bi-caret-up-fill"></i>
      </span>
    """
  end

  defp link_to_new_item_content(_conn) do
    text = dgettext("items", "Add item")

    "+ #{text}"
  end

  defp link_to_new_item_classes(%{params: %{"tour" => _}}) do
    "btn btn-outline-primary btn-lg border border-primary rounded-pill font-weight-semi-bold tour-target"
  end

  defp link_to_new_item_classes(_conn) do
    "btn btn-outline-primary btn-lg border border-primary rounded-pill font-weight-semi-bold"
  end

  defp term(search) do
    search
    |> html_escape()
    |> safe_to_string()
  end
end
