defmodule Tq2Web.Order.CommentsComponent do
  use Tq2Web, :live_component

  import Tq2Web.Utils, only: [localize_datetime: 2]

  alias Tq2.Messages
  alias Tq2.Messages.Comment

  @impl true
  def update(%{order: order, account: account, originator: originator} = assigns, socket) do
    if connected?(socket), do: Messages.subscribe(order)

    changeset = Messages.change_comment(%Comment{})
    comments = Messages.list_comments(order.id)
    account = Tq2.Repo.preload(account, owner: :subscriptions)

    socket =
      socket
      |> assign(
        originator: originator,
        owner: account.owner,
        comments: comments,
        last_comment: List.last(comments),
        changeset: changeset,
        order: order,
        account: account,
        show_originator: true,
        random: :random.uniform(),
        empty_extra_classes: assigns[:empty_extra_classes]
      )

    {:ok, socket}
  end

  @impl true
  def update(%{comment: comment}, %{assigns: %{last_comment: last_comment}} = socket) do
    show_originator = last_comment == nil || last_comment.originator != comment.originator

    # Random hack must be done for https://github.com/phoenixframework/phoenix_live_view/issues/624
    socket =
      socket
      |> assign(
        show_originator: show_originator,
        random: :random.uniform(),
        last_comment: comment,
        comments: [comment]
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"comment" => comment_params},
        %{assigns: %{order: order, originator: originator}} = socket
      ) do
    params =
      comment_params
      |> Map.put("order_id", order.id)
      |> Map.put("originator", originator)

    case Messages.create_comment(params) do
      {:ok, _comment} ->
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

  defp form_options(myself) do
    [id: "comment-form", class: "fixed-bottom mx-4 pb-1", phx_submit: "save", phx_target: myself]
  end

  defp originator_name(%{originator: originator} = assigns, %Comment{
         id: id,
         originator: originator
       }) do
    assigns
    |> originator_name(originator)
    |> originator_tag(id, "text-right")
  end

  defp originator_name(assigns, %Comment{id: id, originator: originator}) do
    assigns
    |> originator_name(originator)
    |> originator_tag(id)
  end

  defp originator_name(%{account: account}, "user") do
    account.name
  end

  defp originator_name(%{order: order}, "customer") do
    order.customer.name
  end

  defp originator_tag(name, id, extra_class \\ nil) do
    content_tag(:p, name,
      id: "comment-originator-#{id}",
      class: "text-primary font-weight-semi-bold mb-2 mt-3 #{extra_class}"
    )
  end

  defp comment_class(%{originator: originator}, %Comment{originator: originator}) do
    "bg-primary-light ml-5"
  end

  defp comment_class(_assigns, _comment) do
    "bg-light mr-5"
  end
end
