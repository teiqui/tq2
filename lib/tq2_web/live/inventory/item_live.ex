defmodule Tq2Web.Inventory.ItemLive do
  use Tq2Web, :live_view

  import Tq2.Utils.CountryCurrency, only: [currency_symbol: 1]

  alias Tq2.Inventories
  alias Tq2.Inventories.Item
  alias Tq2Web.Item.{TourComponent, PromotionalPriceComponent}

  @impl true
  def mount(_params, %{"current_session" => %{} = session}, socket) do
    socket =
      socket
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .gif .png .webp), max_entries: 1)
      |> assign(session: session, item: nil, tour: nil)
      |> add_changeset(%{})

    {:ok, socket}
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
  def handle_params(%{"id" => id}, _uri, %{assigns: %{session: session}} = socket) do
    item = Inventories.get_item!(session.account, id)
    socket = socket |> assign(item: item) |> add_changeset(%{})

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = socket |> assign(tour: params["tour"])

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"_target" => ["image"]}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"item" => params}, socket) do
    socket = socket |> add_changeset(params) |> add_action()

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_event(
        "save",
        %{"item" => item_params},
        %{assigns: %{session: session, item: nil}} = socket
      ) do
    socket = socket |> add_changeset(item_params)

    item_params =
      item_params
      |> put_image_on_params(socket, :image)

    case Inventories.create_item(session, item_params) do
      {:ok, item} ->
        socket =
          socket
          |> put_flash(:info, dgettext("items", "Item created successfully."))
          |> redirect(to: after_create_path(socket, item))

        {:noreply, socket}

      {:error, changeset} ->
        socket = socket |> assign(:changeset, changeset)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "save",
        %{"item" => item_params},
        %{assigns: %{session: session, item: item}} = socket
      ) do
    socket = socket |> add_changeset(item_params)

    item_params =
      item_params
      |> put_image_on_params(socket, :image)

    case Inventories.update_item(session, item, item_params) do
      {:ok, item} ->
        socket =
          socket
          |> put_flash(:info, dgettext("items", "Item updated successfully."))
          |> redirect(to: Routes.item_path(socket, :show, item))

        {:noreply, socket}

      {:error, changeset} ->
        socket = socket |> assign(:changeset, changeset)

        {:noreply, socket}
    end
  end

  defp add_changeset(%{assigns: %{session: %{account: account}, item: nil}} = socket, params) do
    changeset = account |> Inventories.change_item(%Item{}, params)

    socket |> assign(:changeset, changeset)
  end

  defp add_changeset(%{assigns: %{session: %{account: account}, item: item}} = socket, params) do
    changeset = account |> Inventories.change_item(item, params)

    socket |> assign(:changeset, changeset)
  end

  defp add_action(%{assigns: %{changeset: changeset, item: nil}} = socket) do
    assign(socket, :changeset, Map.put(changeset, :action, :insert))
  end

  defp add_action(%{assigns: %{changeset: changeset, item: _item}} = socket) do
    assign(socket, :changeset, Map.put(changeset, :action, :update))
  end

  defp categories(account) do
    account
    |> Tq2.Inventories.list_categories()
    |> Enum.map(&[key: &1.name, value: &1.id])
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, item) do
    hidden_input(form, :lock_version, value: item.lock_version)
  end

  defp submit_label(nil), do: dgettext("items", "Create")
  defp submit_label(_), do: dgettext("items", "Update")

  def submit_button(item) do
    item
    |> submit_label()
    |> submit(
      class: "btn btn-outline-info border border-info rounded-pill font-weight-semi-bold",
      phx_disable_with: dgettext("items", "Saving...")
    )
  end

  defp promotional_price_input(%{country: country}, form) do
    hint =
      dgettext(
        "items",
        "This price is the main element to attract new customers, we recommend that you have about 40% discount on the normal price."
      )

    input(
      form,
      :promotional_price,
      dgettext("items", "Promotional price"),
      label_html: [class: "text-primary"],
      input_html: [prepend: currency_symbol(country), hint: hint, phx_debounce: "blur"]
    )
  end

  defp image(nil) do
    ~E"""
      <svg class="rounded mb-1"
           viewBox="0 0 100 100"
           width="100"
           height="100"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= dgettext("items", "New item image") %>">
        <g>
          <title><%= dgettext("items", "New image") %></title>
          <rect width="100" height="100" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= dgettext("items", "New image") %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: nil} = item) do
    ~E"""
      <svg class="rounded mb-1"
           viewBox="0 0 100 100"
           width="100"
           height="100"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= item.name %>">
        <g>
          <title><%= item.name %></title>
          <rect width="100" height="100" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(item.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: image} = item) do
    url = Tq2.ImageUploader.url({image, item}, :thumb)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "100",
      height: "100",
      loading: "lazy",
      alt: item.name,
      class: "rounded mb-1"
    )
  end

  defp put_image_on_params(nil, params, _upload) do
    params
  end

  defp put_image_on_params(%Plug.Upload{} = image, params, upload) do
    Map.put(params, to_string(upload), image)
  end

  defp put_image_on_params(params, %{assigns: %{changeset: %{valid?: true}}} = socket, upload) do
    consume_uploaded_entries(socket, upload, fn meta, entry ->
      path = "#{meta.path}-#{upload}"

      File.cp!(meta.path, path)

      %Plug.Upload{
        content_type: entry.client_type,
        filename: entry.client_name,
        path: path
      }
    end)
    |> List.first()
    |> put_image_on_params(params, upload)
  end

  defp put_image_on_params(params, _socket, _upload) do
    params
  end

  defp image_input_class(form, field, upload) do
    class = "custom-file-input text-truncate"

    case image_errors(form, field, upload) do
      [] -> class
      _ -> "#{class} is-invalid"
    end
  end

  defp image_label(upload) do
    case upload.entries |> List.first() do
      nil -> dgettext("items", "Image")
      entry -> entry.client_name
    end
  end

  defp image_errors(form, field, upload) do
    upload_errors =
      for entry <- upload.entries, error <- upload_errors(upload, entry) do
        error_to_string(error)
      end

    case form.errors[field] do
      nil -> upload_errors
      _ -> upload_errors ++ translate_errors(form, field)
    end
  end

  defp image_errors_tag(form, field, upload) do
    form
    |> image_errors(field, upload)
    |> image_errors_tag()
  end

  defp image_errors_tag([]) do
    nil
  end

  defp image_errors_tag(errors) do
    content_tag(:div, Enum.join(errors, ", "), class: "invalid-feedback")
  end

  defp error_to_string(:too_large) do
    dgettext("errors", "Too large, maximum is %{size}", size: "8 MB")
  end

  defp error_to_string(:too_many_files) do
    dgettext("errors", "You have selected too many files, maximum is %{count}", count: 1)
  end

  defp error_to_string(:not_accepted) do
    dgettext("errors", "You have selected an unacceptable file type")
  end

  defp translate_errors(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), &Tq2Web.ErrorHelpers.translate_error/1)
  end

  defp after_create_path(%{assigns: %{tour: nil}} = socket, item) do
    Routes.item_path(socket, :show, item)
  end

  defp after_create_path(socket, _item) do
    Routes.item_path(socket, :index, tour: "item_created")
  end
end
