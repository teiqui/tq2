defmodule Tq2.Notifications do
  alias Tq2.Accounts.User
  alias Tq2.Notifications.{Mailer, Email}
  alias Tq2.Sales.Order

  def send_password_reset(%User{} = user) do
    user
    |> Email.password_reset()
    |> deliver_later()
  end

  def send_new_order(%Order{} = order, recipient) do
    order
    |> Email.new_order(recipient)
    |> deliver_later()
  end

  def send_promotion_confirmation(%Order{} = order) do
    order
    |> Email.promotion_confirmation()
    |> deliver_later()
  end

  def send_expired_promotion(%Order{} = order) do
    order
    |> Email.expired_promotion()
    |> deliver_later()
  end

  defp deliver_later(nil), do: nil
  defp deliver_later(email), do: Mailer.deliver_later(email)
end
