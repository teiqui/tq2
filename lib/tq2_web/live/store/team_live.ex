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

  defp avatar(%Tq2.Sales.Customer{name: name}) do
    initial =
      name
      |> String.replace(~r/\W+/, "")
      |> String.upcase()
      |> String.first()

    ~E"""
      <svg class="mr-3"
           viewBox="0 0 60 60"
           width="60"
           height="60"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= name %>">
        <g>
          <title><%= name %></title>
          <ellipse cx="30" cy="30" rx="30" ry="30" fill="#c4c4c4"></ellipse>
          <text class="h1 font-weight-semi-bold"
                x="50%"
                y="50%"
                text-anchor="middle"
                alignment-baseline="middle"
                dominant-baseline="middle"
                fill="#838383"
                dy=".1em">
            <%= initial || "T" %>
          </text>
        </g>
      </svg>
    """
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
