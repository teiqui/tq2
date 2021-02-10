defmodule Tq2Web.Store.CounterLive do
  use Tq2Web, :live_view

  alias Tq2.{Analytics, Inventories, Sales, Transactions}
  alias Tq2.Transactions.Cart
  alias Tq2Web.Store.{ButtonComponent, CategoryComponent, HeaderComponent, ItemComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(
        store: store,
        token: token,
        visit_id: visit_id,
        referral_customer: visit.referral_customer,
        referred: !!visit.referral_customer
      )
      |> put_teiqui_price_info()

    {:ok, socket,
     temporary_assigns: [cart: nil, items: [], categories: nil, referral_customer: nil]}
  end

  @impl true
  def handle_params(params, _, socket) do
    category_id =
      case Integer.parse(params["category"] || "") do
        :error -> nil
        {id, ""} -> id
      end

    query = String.trim(params["search"] || "")

    socket =
      socket
      |> load_defaults()
      |> assign(search: query)
      |> load_category(category_id)
      |> load_items()
      |> hide_categories()

    {:noreply, socket}
  end

  @impl true
  def handle_event("load-more", _, socket) do
    socket =
      socket
      |> update(:page, &(&1 + 1))
      |> load_cart()
      |> load_items()

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "toggle-categories",
        _,
        %{assigns: %{show_categories: false}} = socket
      ) do
    socket =
      socket
      |> toggle_show_categories()
      |> load_cart()
      |> load_categories()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-categories", _, socket) do
    socket =
      socket
      |> toggle_show_categories()
      |> assign(page: 1)
      |> load_cart()
      |> load_items()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", params, %{assigns: %{store: store}} = socket) do
    extras =
      socket
      |> assign(search: params["search"])
      |> extra_params()

    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store, extras))

    {:noreply, socket}
  end

  defp load_cart(
         %{assigns: %{referred: referred, store: %{account: account}, token: token}} = socket
       ) do
    cart = Transactions.get_cart(account, token) || %Cart{referred: referred, lines: []}

    assign(socket, cart: cart)
  end

  defp load_items(%{assigns: %{store: %{account: account}}} = socket) do
    items = Inventories.list_visible_items(account, item_params(socket))

    assign(socket, items: items)
  end

  defp item_params(%{assigns: %{page: page, page_size: page_size} = assigns}) do
    attrs = %{page: page, page_size: page_size}

    attrs =
      case assigns[:category] do
        nil -> attrs
        category -> Map.put(attrs, :category_id, category.id)
      end

    attrs =
      case assigns[:search] do
        query when is_binary(query) and query != "" -> Map.put(attrs, :search, query)
        _ -> attrs
      end

    attrs
  end

  defp page_size do
    case Application.get_env(:tq2, :env) do
      :test -> 1
      _ -> 12
    end
  end

  defp load_categories(%{assigns: %{store: %{account: account}}} = socket) do
    categories = Tq2.Inventories.categories_with_images(account)

    assign(socket, categories: categories)
  end

  defp toggle_show_categories(%{assigns: %{show_categories: show}} = socket) do
    assign(socket, show_categories: !show)
  end

  defp hide_categories(socket) do
    assign(socket, show_categories: false)
  end

  defp load_defaults(socket) do
    default_options = %{
      page: 1,
      page_size: page_size(),
      show_categories: false,
      categories: nil,
      category: nil
    }

    socket
    |> assign(default_options)
    |> load_cart()
  end

  def link_show_all(socket, store) do
    live_patch(
      dgettext("stores", "Show all"),
      to: Routes.counter_path(socket, :index, store),
      class: "text-decoration-none text-center d-block",
      id: "show_all",
      phx_hook: "ScrollToTop"
    )
  end

  defp extra_params(%{assigns: assigns}) do
    Enum.reject(
      %{
        search: assigns[:search],
        category: if(assigns[:category], do: assigns[:category].id)
      },
      fn {_, v} -> is_nil(v) or v == "" end
    )
  end

  defp put_teiqui_price_info(%{assigns: %{token: token}} = socket) do
    show? = !Sales.customer_exists?(token)

    socket |> assign(:show_teiqui_price_info, show?)
  end

  defp load_category(socket, nil), do: socket

  defp load_category(%{assigns: %{store: %{account: account}}} = socket, id) do
    category = Tq2.Inventories.get_category!(account, id)

    socket |> assign(:category, category)
  end
end
