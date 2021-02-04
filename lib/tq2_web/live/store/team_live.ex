defmodule Tq2Web.Store.TeamLive do
  use Tq2Web, :live_view

  alias Tq2.Sales
  alias Tq2Web.Store.{HeaderComponent, ShareComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    default_options = %{
      page: 1,
      page_size: page_size(),
      store: store,
      token: token,
      visit_id: visit_id
    }

    socket =
      socket
      |> assign(default_options)
      |> load_orders()

    {:ok, socket,
     temporary_assigns: [cart: nil, orders: %Scrivener.Page{}, referral_customer: nil]}
  end

  @impl true
  def handle_event("load-more", _, socket) do
    socket =
      socket
      |> update(:page, &(&1 + 1))
      |> load_orders()

    {:noreply, socket}
  end

  defp load_orders(%{assigns: %{store: %{account: account}}} = socket) do
    orders = Sales.list_unexpired_orders(account, order_params(socket))

    assign(socket, orders: orders)
  end

  defp order_params(%{assigns: %{page: page, page_size: page_size}}) do
    %{page: page, page_size: page_size}
  end

  defp page_size do
    case Application.get_env(:tq2, :env) do
      :test -> 1
      _ -> 12
    end
  end

  defp avatar(socket, %Tq2.Sales.Customer{id: id} = customer) do
    color_index = rem(id, 5)
    avatar_index = avatar_index(id)
    {color, _} = ~w(457b9d f8c647 cc0000 73b8bb 6980a2) |> List.pop_at(color_index)

    socket
    |> Routes.static_path("/images/avatars/avatar_#{avatar_index}.svg")
    |> img_tag(
      height: 60,
      width: 60,
      alt: first_name(customer),
      style: "background-color: ##{color};",
      class: "rounded-circle mr-3"
    )
  end

  defp avatar_index(id) do
    id
    |> rem(15)
    |> Kernel.+(1)
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end

  defp first_name(%Tq2.Sales.Customer{name: name}) do
    name
    |> String.split(~r/\s+/)
    |> List.first()
  end

  defp time_to_expire(%Tq2.Sales.Order{promotion_expires_at: promotion_expires_at}) do
    promotion_expires_at
    |> Timex.diff(Timex.now(), :seconds)
    |> Timex.Duration.from_seconds()
    |> Timex.Duration.to_time!()
    |> Time.to_iso8601()
  end

  def link_to_join(socket, store, order) do
    token = List.first(order.customer.tokens)

    path =
      Routes.counter_path(socket, :index, store,
        referral: token.value,
        utm_source: "team",
        refresh_visit: true
      )

    link(dgettext("stores", "Join"),
      to: path,
      class: "btn btn-sm btn-outline-primary border border-primary rounded-pill"
    )
  end
end
