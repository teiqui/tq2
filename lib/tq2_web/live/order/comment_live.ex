defmodule Tq2Web.Order.CommentLive do
  use Tq2Web, :live_view

  alias Tq2.Sales
  alias Tq2Web.Order.CommentsComponent

  @impl true
  def mount(%{"id" => id}, %{"current_session" => %{account: account}}, socket) do
    order = Sales.get_order!(account, id)
    socket = socket |> assign(account: account, order: order)

    {:ok, socket, temporary_assigns: [comments: []]}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  @impl true
  def handle_info({:comment_created, comment}, socket) do
    send_update(CommentsComponent, id: :comments, comment: comment)

    {:noreply, socket}
  end
end
