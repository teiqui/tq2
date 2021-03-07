defmodule Tq2Web.Store.PaymentController do
  use Tq2Web, :controller

  alias Tq2.Gateways.Transbank
  alias Tq2.Payments
  alias Tq2.Payments.Payment
  alias Tq2.Transactions.Cart

  @doc """
  Controller without CSRF protection.

  These actions are called from a vendor modal iframe.
  """

  def action(%{assigns: %{store: store}} = conn, _) do
    session = %{store: store}

    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def transbank(conn, %{"id" => id, "channel" => channel}, %{store: store}) do
    cart = store.account |> Tq2.Transactions.get_cart!(id)

    cart
    |> get_payment()
    |> create_preference(cart, channel, store)
    |> respond_with_payment(conn)
  end

  defp create_preference(nil, _cart, _channel, _store), do: nil

  defp create_preference(%Payment{} = payment, cart, channel, store) do
    payment = %{payment | cart: cart}

    store.account
    |> Tq2.Apps.get_app("transbank")
    |> create_full_or_partial_preference(payment, cart, store, channel)
    |> maybe_update_payment(cart, payment)
  end

  defp create_full_or_partial_preference(app, payment, cart, store, channel) do
    case payment.amount == Cart.total(cart) do
      true ->
        Transbank.create_cart_preference(app, cart, store, channel)

      false ->
        Transbank.create_partial_preference(app, payment, store, channel)
    end
  end

  defp maybe_update_payment(%{"responseCode" => "OK", "result" => result}, cart, payment) do
    payment = %{payment | cart: cart}
    attrs = %{external_id: result["externalUniqueNumber"], gateway_data: result}

    case Tq2.Payments.update_payment(cart, payment, attrs) do
      {:ok, payment} ->
        payment

      {:error, changeset} ->
        Sentry.capture_message("[Tbk] Payment update", extra: changeset.errors)

        nil
    end
  end

  defp maybe_update_payment(_response, _cart, _payment), do: nil

  defp respond_with_payment(
         %Payment{gateway_data: %{} = result, amount: %{amount: amount}},
         conn
       ) do
    attrs = result |> Map.put("amount", amount) |> Map.delete("signature")

    json(conn, attrs)
  end

  defp respond_with_payment(_payment, conn), do: json(conn, %{})

  defp get_payment(nil), do: nil

  defp get_payment(cart) do
    cart |> Payments.get_pending_payment_for_cart_and_kind("transbank")
  end
end
