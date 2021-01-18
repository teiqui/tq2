defmodule Tq2Web.Dashboard.MainLive do
  use Tq2Web, :live_view

  alias Tq2.{Accounts, Analytics, Sales, Shops}
  alias Tq2Web.Store.ShareComponent

  @impl true
  def mount(_params, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    store = Shops.get_store!(session.account)
    amount = Sales.orders_sale_amount(session.account)
    counts = Sales.orders_by_status_count(session.account)
    visits = Analytics.visit_counts(store.slug)

    socket =
      socket
      |> assign(
        store: store,
        amount: amount,
        counts: counts,
        visits: visits,
        account_id: account_id,
        user_id: user_id
      )

    {:ok, socket, temporary_assigns: [store: nil, counts: []]}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  defp current_visits({0, _}) do
    dgettext("dashboard", "There are no visits yet.")
  end

  defp current_visits({count, _}) do
    count
  end

  defp performance({0, 0}) do
    dgettext("dashboard", "There is not enough data.")
  end

  defp performance({_, 0}) do
    content_tag(:span, "+ 100%", class: "badge badge-info px-2")
  end

  defp performance({count, count}) do
    content_tag(:span, "0%", class: "badge badge-info px-2")
  end

  defp performance({current, previous}) do
    sign = if current >= previous, do: "+", else: "-"

    amount =
      (current * 100)
      |> Decimal.new()
      |> Decimal.div_int(previous)
      |> Decimal.sub(100)
      |> Decimal.round(1)
      |> Decimal.abs()

    content_tag(:span, "#{sign} #{amount}%", class: "badge badge-info px-2")
  end

  defp performance_hint({0, 0}) do
    nil
  end

  defp performance_hint({_, _}) do
    content_tag(:span, dgettext("dashboard", "* In relation to the previous day."),
      class: "small text-muted float-right"
    )
  end

  defp count(counts, price_type, status) do
    statuses =
      case status do
        "pending" -> ~w(pending processing)
        "finished" -> ~w(completed)
      end

    counts
    |> Enum.filter(fn {s, pt, _count} -> s in statuses && pt == price_type end)
    |> Enum.map(fn {_s, _pt, count} -> count end)
    |> Enum.sum()
  end
end
