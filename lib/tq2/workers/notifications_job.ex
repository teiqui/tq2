defmodule Tq2.Workers.NotificationsJob do
  import Tq2.Utils.Urls, only: [app_uri: 0, store_uri: 0]
  import Tq2Web.Gettext

  alias Tq2.Accounts
  alias Tq2.Messages
  alias Tq2.Messages.Comment
  alias Tq2.Notifications
  alias Tq2.Notifications.Subscription
  alias Tq2.Repo
  alias Tq2.Sales
  alias Tq2.Sales.Order
  alias Tq2.Shops.Store
  alias Tq2Web.Router.Helpers, as: Routes

  def perform("new_comment", account_id, order_id, customer_id, comment_id) do
    account = Accounts.get_account!(account_id)
    order = Sales.get_order!(account, order_id)
    comment = Messages.get_comment!(comment_id)
    body = body(account.store, order, comment)

    account
    |> subscriptions(comment, customer_id)
    |> Enum.each(&send_web_push(body, &1))

    {:ok, _comment} = Messages.update_comment(comment, %{status: "delivered"})
  end

  def perform("new_order", account_id, order_id, user_id) do
    account = Accounts.get_account!(account_id)
    order = Sales.get_order!(account, order_id)
    user = account |> Accounts.get_user!(user_id) |> Repo.preload(:subscriptions)
    body = body(order)

    Enum.each(user.subscriptions, &send_web_push(body, &1))
  end

  defp send_web_push(body, subscription) do
    body
    |> WebPushEncryption.send_web_push(subscription.data)
    |> handle_response(subscription)
  end

  defp body(%Store{} = store, %Order{} = order, %Comment{originator: "user"} = comment) do
    Jason.encode!(%{
      title: dgettext("notifications", "You have a new comment on your order!"),
      body: dgettext("notifications", "Tap or click to view the details."),
      tag: "order-comment-notification-#{comment.id}",
      lang: Gettext.get_locale(Tq2Web.Gettext),
      data: %{
        path: Routes.order_path(store_uri(), :index, store, order, status: true)
      }
    })
  end

  defp body(%Store{}, %Order{} = order, %Comment{originator: "customer"} = comment) do
    Jason.encode!(%{
      title:
        dgettext("notifications", "You have a new comment on order #%{number}!", number: order.id),
      body: dgettext("notifications", "Tap or click to view the details."),
      tag: "order-comment-notification-#{comment.id}",
      lang: Gettext.get_locale(Tq2Web.Gettext),
      data: %{
        path: Routes.order_path(app_uri(), :show, order)
      }
    })
  end

  defp body(%Order{} = order) do
    Jason.encode!(%{
      title: dgettext("notifications", "You have a new order!"),
      body: dgettext("notifications", "Tap or click to view the details."),
      tag: "order-notification-#{order.id}",
      lang: Gettext.get_locale(Tq2Web.Gettext),
      data: %{
        path: Routes.order_path(app_uri(), :show, order)
      }
    })
  end

  defp handle_response({:ok, _response} = result, %Subscription{error_count: 0}) do
    result
  end

  defp handle_response({:ok, _response} = result, %Subscription{} = subscription) do
    {:ok, _subscription} = Notifications.update_subscription(subscription, %{error_count: 0})

    result
  end

  defp handle_response({:error, message} = result, %Subscription{} = subscription) do
    {:ok, _subscription} =
      Notifications.update_subscription(subscription, %{error_count: subscription.error_count + 1})

    Sentry.capture_message("Push notification error",
      extra: %{subscription_id: subscription.id, message: message}
    )

    result
  end

  defp subscriptions(_account, %Comment{originator: "user"}, customer_id) do
    customer = customer_id |> Sales.get_customer!() |> Repo.preload(:subscriptions)

    customer.subscriptions
  end

  defp subscriptions(account, _comment, _customer_id) do
    account = Repo.preload(account, owner: :subscriptions)

    account.owner.subscriptions
  end
end
