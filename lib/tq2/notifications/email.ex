defmodule Tq2.Notifications.Email do
  use Bamboo.Phoenix, view: Tq2Web.EmailView

  import Bamboo.Email
  import Tq2Web.Gettext

  alias Tq2.Accounts.User
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.Cart

  def password_reset(%User{} = user) do
    subject = dgettext("emails", "Password reset")

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> render(:password_reset, user: user)
  end

  def new_order(%Order{}, %Customer{email: nil}), do: nil

  def new_order(%Order{} = order, %Customer{} = customer) do
    subject = dgettext("emails", "New order")
    shipping = Cart.shipping(order.cart)

    base_email()
    |> to(customer.email)
    |> subject(subject)
    |> render(:order_confirmation, order: order, customer: customer, shipping: shipping)
  end

  def new_order(%Order{} = order, %User{} = user) do
    subject = dgettext("emails", "New order")
    shipping = Cart.shipping(order.cart)

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> render(:owner_order_confirmation, order: order, user: user, shipping: shipping)
  end

  def new_order(%Order{}, nil), do: nil

  def promotion_confirmation(%Order{customer: %Customer{email: nil}}), do: nil

  def promotion_confirmation(%Order{customer: customer} = order) do
    subject = dgettext("emails", "Promotion confirmed")
    shipping = Cart.shipping(order.cart)

    base_email()
    |> to(customer.email)
    |> subject(subject)
    |> render(:promotion_confirmation, order: order, customer: customer, shipping: shipping)
  end

  def expired_promotion(%Order{customer: %Customer{email: nil}}), do: nil

  def expired_promotion(%Order{customer: customer} = order) do
    subject = dgettext("emails", "Promotional price expired")
    shipping = Cart.shipping(order.cart)

    base_email()
    |> to(customer.email)
    |> subject(subject)
    |> render(:expired_promotion, order: order, customer: customer, shipping: shipping)
  end

  defp base_email() do
    address = System.get_env("EMAIL_ADDRESS", "support@teiqui.com")

    new_email()
    |> from({gettext("Teiqui 🔔"), address})
    |> put_layout({Tq2Web.LayoutView, :email})
  end
end
