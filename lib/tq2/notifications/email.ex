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
    |> reply_to(order.account_id)
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
    |> reply_to(order.account_id)
    |> render(:promotion_confirmation, order: order, customer: customer, shipping: shipping)
  end

  def expired_promotion(%Order{customer: %Customer{email: nil}}), do: nil

  def expired_promotion(%Order{customer: customer} = order) do
    subject = dgettext("emails", "Promotional price expired")
    shipping = Cart.shipping(order.cart)
    order = Tq2.Repo.preload(order, :store)

    base_email()
    |> to(customer.email)
    |> subject(subject)
    |> reply_to(order.account_id)
    |> render(:expired_promotion, customer: customer, order: order, shipping: shipping)
  end

  def license_near_to_expire(%User{} = user) do
    subject = dgettext("emails", "License near to expire")

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> render(:license_near_to_expire, user: user)
  end

  def license_expired(%User{} = user) do
    subject = dgettext("emails", "License expired")

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> render(:license_expired, user: user)
  end

  def cart_reminder(%Cart{}, %Customer{email: nil}), do: nil

  def cart_reminder(%Cart{} = cart, %Customer{} = customer) do
    subject = dgettext("emails", "Finish your purchase!")
    shipping = Cart.shipping(cart)

    base_email()
    |> to(customer.email)
    |> subject(subject)
    |> reply_to(cart.account_id)
    |> render(:cart_reminder, cart: cart, customer: customer, shipping: shipping)
  end

  defp base_email() do
    new_email()
    |> from({gettext("Teiqui 🔔"), default_email()})
    |> put_layout({Tq2Web.LayoutView, :email})
  end

  defp default_email do
    System.get_env("EMAIL_ADDRESS", "support@teiqui.com")
  end

  defp reply_to(email, account_id) do
    reply_to = email_for(account_id) || default_email()

    email |> put_header("Reply-To", reply_to)
  end

  defp email_for(account_id) do
    account = Tq2.Accounts.get_account!(account_id)
    store = Tq2.Shops.get_store!(account)

    case store.data && store.data.email do
      nil ->
        owner = Tq2.Accounts.get_owner(account)

        owner && owner.email && "#{store.name} <#{owner.email}>"

      email ->
        "#{store.name} <#{email}>"
    end
  end
end
