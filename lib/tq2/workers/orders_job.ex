defmodule Tq2.Workers.OrdersJob do
  alias Tq2.Sales
  alias Tq2.Sales.Order
  alias Tq2.Transactions

  def perform(order_id) do
    order_id
    |> Sales.get_not_referred_pending_order()
    |> expire_promotional_price()
  rescue
    ex ->
      # TODO: Change to set_context when it's fixed
      # https://github.com/getsentry/sentry-elixir/issues/349
      Sentry.capture_exception(ex,
        stacktrace: __STACKTRACE__,
        extra: %{order_id: order_id},
        tags: %{worker: __MODULE__}
      )

      raise ex
  end

  defp expire_promotional_price(%Order{} = order) do
    order.account
    |> Transactions.update_cart(order.cart, %{price_type: "regular"})
    |> notify_expired_promotion(order)
  end

  defp expire_promotional_price(_), do: nil

  defp notify_expired_promotion({:ok, _}, order) do
    cart = %{order.cart | price_type: "regular"}

    %{order | cart: cart} |> Tq2.Notifications.send_expired_promotion()
  end

  defp notify_expired_promotion({:error, %{changes: changes, errors: errors}}, order) do
    Sentry.capture_message("Cannot update Cart to regular price",
      extra: %{
        order_id: order.id,
        errors: inspect(errors),
        changes: changes
      }
    )
  end
end
