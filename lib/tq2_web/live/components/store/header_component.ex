defmodule Tq2Web.Store.HeaderComponent do
  use Tq2Web, :live_component

  alias Tq2.Analytics
  alias Tq2.Shops.Store
  alias Tq2Web.Store.{InformationComponent, ShareComponent, TeamComponent}

  def update(%{referral_customer: _} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def update(%{visit_id: visit_id} = assigns, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(referral_customer: visit.referral_customer)

    {:ok, socket}
  end

  defp image(socket, %Store{logo: nil} = store) do
    path = Routes.static_path(socket, "/images/store_default_logo.svg")

    img_tag(path,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid rounded-circle"
    )
  end

  defp image(_socket, %Store{logo: logo} = store) do
    url = Tq2.LogoUploader.url({logo, store}, :thumb)

    set = %{
      url => "1x",
      Tq2.LogoUploader.url({logo, store}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid rounded-circle"
    )
  end

  defp share_classes do
    "btn btn-sm btn-light text-primary rounded-circle h-28-px w-28-px p-1 mt-n1"
  end

  defp chevron_direction(conn, true), do: icon_tag(conn, "chevron-up")
  defp chevron_direction(conn, _), do: icon_tag(conn, "chevron-down")

  defp icon_tag(conn, icon) do
    options = [class: "bi", width: "14", height: "14", fill: "currentColor"]
    icon_path = Routes.static_path(conn, "/images/bootstrap-icons.svg##{icon}")

    content_tag(:svg, options) do
      raw("<use xlink:href=\"#{icon_path}\"/>")
    end
  end

  defp search_input(assigns) do
    assigns = if assigns[:search], do: assigns, else: Map.put(assigns, :search, "")

    ~L"""
    <form phx-submit="search">
      <div class="input-group ml-n2">
        <div class="input-group-prepend">
          <button type="submit" class="btn btn-outline-primary px-2">
            <%= icon_tag(@socket, "search") %>
          </button>
        </div>
        <input type="text"
               name="search"
               value="<%= @search %>"
               class="form-control shadow-none text-primary"
               placeholder="<%= dgettext("stores", "Search...") %>"
               autocomplete="off"
               id="search-input">
      </div>
    </form>
    """
  end
end
