defmodule Tq2Web.Store.NotificationComponent do
  use Tq2Web, :live_component

  alias Tq2.Notifications

  @impl true
  def update(%{inner_block: inner_block} = assigns, socket) do
    socket =
      socket
      |> assign(
        inner_block: inner_block,
        user_id: assigns[:user_id],
        customer_id: assigns[:customer_id],
        ask_for_notifications: assigns[:ask_for_notifications]
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("ask-for-notifications", _params, socket) do
    {:noreply, assign(socket, ask_for_notifications: true)}
  end

  @impl true
  def handle_event("subscribe", _params, socket) do
    {:noreply, push_event(socket, "subscribe", %{})}
  end

  @impl true
  def handle_event("dismiss", _params, socket) do
    {:noreply, assign(socket, ask_for_notifications: false)}
  end

  @impl true
  def handle_event("register", params, socket) do
    attrs =
      %{"data" => params}
      |> put_subscription_attrs(socket)

    case save_subscription(attrs) do
      {:ok, _subscription} ->
        socket =
          socket
          |> push_event("registered", %{})
          |> assign(ask_for_notifications: false)

        {:noreply, socket}

      {:error, _changeset} ->
        # TODO: handle this case properly
        {:noreply, socket}
    end
  end

  defp put_subscription_attrs(attrs, %{assigns: %{customer_id: customer_id, user_id: nil}}) do
    Map.put(attrs, "customer_subscription", %{"customer_id" => customer_id})
  end

  defp put_subscription_attrs(attrs, %{assigns: %{customer_id: nil, user_id: user_id}}) do
    Map.put(attrs, "subscription_user", %{"user_id" => user_id})
  end

  defp save_subscription(attrs) do
    case Notifications.get_subscription(attrs) do
      nil ->
        Notifications.create_subscription(attrs)

      subscription ->
        Notifications.update_subscription(subscription, attrs)
    end
  end

  defp vapid_server_key do
    Application.get_env(:web_push_encryption, :vapid_details)[:public_key]
  end
end
