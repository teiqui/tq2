defmodule Tq2Web.CartController do
  use Tq2Web, :controller

  alias Tq2.Transactions

  def show(%{assigns: %{store: store}} = conn, %{"from" => id}) do
    account = store.account

    from_cart_id = id |> String.to_integer()
    token = conn |> get_session(:token)
    visit_id = conn |> get_session(:visit_id)

    account
    |> Transactions.get_cart(token)
    |> process(from_cart_id, account: account, token: token, visit_id: visit_id)

    conn |> redirect(to: Routes.brief_path(conn, :index, store))
  end

  # same cart
  defp process(%{id: id}, id, _extras), do: nil

  # without current_cart
  defp process(nil, from_id, account: account, token: token, visit_id: visit_id) do
    attrs = %{token: token, price_type: "promotional", visit_id: visit_id}

    case Transactions.create_cart(account, attrs) do
      {:ok, cart} -> %{cart | account: account, lines: []} |> copy_lines_from(from_id)
      {:error, _changeset} -> nil
    end
  end

  # With current cart
  defp process(cart, from_id, [{:account, account} | _]) do
    cart |> Map.put(:account, account) |> copy_lines_from(from_id)
  end

  defp copy_lines_from(cart, from_id) do
    cart.account
    |> Transactions.get_cart!(from_id)
    |> Transactions.copy_lines(cart)
    |> handle_results()
  end

  defp handle_results({:ok, _}), do: nil

  defp handle_results({:error, operation, cs, _}) do
    Sentry.capture_message(
      "Clone cart error",
      extra: %{operation: operation, errors: inspect(cs.errors)}
    )

    nil
  end
end
