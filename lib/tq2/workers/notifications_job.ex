defmodule Tq2.Workers.NotificationsJob do
  import Tq2.Utils.Urls, only: [app_uri: 0, store_uri: 0]
  import Tq2Web.Gettext

  alias Tq2.{Accounts, Messages, News, Notifications, Sales}
  alias Tq2.Messages.Comment
  alias Tq2.News.Note
  alias Tq2.Notifications.{Email, Mailer, Subscription}
  alias Tq2.Repo
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

  def perform("new_note", note_id) do
    note_id
    |> News.get_note!()
    |> notify_new_note()
  end

  def perform("notify_abandoned_cart_to_user", account_id, cart_token) do
    account_id
    |> Accounts.get_account!()
    |> Tq2.Transactions.get_cart(cart_token)
    |> notify_abandoned_cart_to_user()
  end

  def perform("notify_abandoned_cart_to_customer", account_id, cart_token) do
    account_id
    |> Accounts.get_account!()
    |> Tq2.Transactions.get_cart(cart_token)
    |> notify_abandoned_cart_to_customer()
  end

  defp notify_abandoned_cart_to_user(nil), do: nil

  defp notify_abandoned_cart_to_user(%{account: account} = cart) do
    body = cart |> abandoned_cart_body()

    account
    |> subscriptions()
    |> Enum.each(&send_web_push(body, &1))
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

  defp body(%Note{} = note) do
    Jason.encode!(%{
      title: note.title,
      body: note.body,
      tag: "note-notification-#{note.id}",
      lang: Gettext.get_locale(Tq2Web.Gettext)
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

  defp abandoned_cart_body(%{id: id}) do
    Jason.encode!(%{
      title: dgettext("notifications", "A customer left an incomplete purchase!"),
      body: dgettext("notifications", "Tap or click to view the details."),
      tag: "cart-notification-#{id}",
      lang: Gettext.get_locale(Tq2Web.Gettext),
      data: %{
        path: Routes.cart_path(app_uri(), :show, id)
      }
    })
  end

  defp subscriptions(account, comment \\ nil, customer_id \\ nil)

  defp subscriptions(_account, %Comment{originator: "user"}, customer_id) do
    customer = customer_id |> Sales.get_customer!() |> Repo.preload(:subscriptions)

    customer.subscriptions
  end

  defp subscriptions(account, _comment, _customer_id) do
    account = Repo.preload(account, owner: :subscriptions)

    account.owner.subscriptions
  end

  # Customer without email can't be notified at the moment
  defp notify_abandoned_cart_to_customer(nil), do: nil
  defp notify_abandoned_cart_to_customer(%{customer: %{email: nil}}), do: nil

  defp notify_abandoned_cart_to_customer(%{customer: customer} = cart) do
    Tq2.Notifications.send_cart_reminder(cart, customer)
  end

  defp notify_new_note(%Note{} = note) do
    Repo.transaction(
      fn ->
        Accounts.stream_accounts()
        |> iterate_stream(note)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  defp iterate_stream(stream, note) do
    # This disgusting piece allow us to test it without too much hack.
    #
    # For some explanation see:
    #
    # - https://elixirforum.com/t/what-is-a-proper-way-to-test-repo-stream-with-task-async-stream/6955
    # - https://qertoip.medium.com/making-sense-of-ecto-2-sql-sandbox-and-connection-ownership-modes-b45c5337c6b7
    # - https://github.com/jjh42/mock/issues/79
    case Application.get_env(:tq2, :env) do
      :test ->
        stream |> Stream.each(&deliver_note(&1, note))

      _ ->
        stream |> Task.async_stream(&deliver_note(&1, note), max_concurrency: 10)
    end
  end

  defp deliver_note(account, note) do
    # Preload can not be done with streams
    account = Repo.preload(account, owner: :subscriptions)
    body = body(note)

    account.owner.subscriptions
    |> Enum.each(&send_web_push(body, &1))

    note
    |> Email.new_note(account.owner)
    |> Mailer.deliver_later!()
  end
end
