defmodule Tq2Web.Order.CommentLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [localize_datetime: 2]

  alias Tq2.Messages
  alias Tq2.Messages.Comment

  @impl true
  def mount(%{"id" => id}, %{"current_session" => %{account: account}}, socket) do
    comments = Messages.list_comments(id)
    changeset = Messages.change_comment(%Comment{})

    socket =
      socket |> assign(account: account, changeset: changeset, comments: comments, order_id: id)

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
  def handle_event(
        "save",
        %{"comment" => comment_params},
        %{assigns: %{order_id: order_id}} = socket
      ) do
    params = Map.put(comment_params, "order_id", order_id)

    case Messages.create_comment(params) do
      {:ok, comment} ->
        changeset = %Comment{} |> Messages.change_comment()

        socket =
          socket
          |> assign(changeset: changeset, comments: [comment])

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp submit_button do
    submit(class: "btn btn-lg btn-link p-0 m-0 mt-n2") do
      ~E"""
        <span class="ml-n5 pl-3">
          <i class="bi-cursor"></i>
          <span class="sr-only"><%= dgettext("comments", "Send") %></span>
        </span>
      """
    end
  end
end
