defmodule Tq2Web.Shop.StoreLive do
  use Tq2Web, :live_view

  alias Tq2.{Accounts, Shops}
  alias Tq2.Shops.Store

  @impl true
  def mount(%{"section" => section}, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    store = Shops.get_store!(session.account)
    changeset = Shops.change_store(session.account, store)

    socket =
      socket
      |> allow_upload(:logo, accept: ~w(.jpg .jpeg .gif .png .webp))
      |> assign(
        account_id: account_id,
        user_id: user_id,
        store: store,
        section: section,
        changeset: changeset
      )

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
  def handle_params(%{"section" => section}, _uri, socket) do
    socket = socket |> assign(section: section)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  @impl true
  def handle_event(
        "save",
        %{"store" => store_params},
        %{assigns: %{account_id: account_id, user_id: user_id}} = socket
      ) do
    session = Accounts.get_current_session(account_id, user_id)
    store = Shops.get_store!(session.account)
    store_params = store_params |> put_logo_on_params(socket, :logo)

    case Shops.update_store(session, store, store_params) do
      {:ok, store} ->
        changeset = Shops.change_store(session.account, store)

        socket =
          socket
          |> put_flash(:info, dgettext("stores", "Store updated successfully."))
          |> assign(store: store, changeset: changeset)

        {:noreply, socket}

      {:error, changeset} ->
        socket = socket |> assign(:changeset, changeset)

        {:noreply, socket}
    end
  end

  defp public_store_link(store) do
    url = store_uri() |> Routes.counter_url(:index, store)

    link(url, to: url, target: "_blank")
  end

  defp link_to_section(socket, caption, to: section) do
    path = Routes.store_path(socket, :index, section)

    content = ~E"""
      <%= caption %>

      <span class="text-primary float-right">
        <svg class="bi" width="12" height="12" fill="currentColor">
          <use xlink:href="<%= Routes.static_path(socket, "/images/bootstrap-icons.svg#chevron-right") %>"/>
        </svg>
      </span>
    """

    live_patch(content, to: path, class: "list-group-item list-group-item-action bg-light py-3")
  end

  defp link_to_main(socket) do
    path = Routes.store_path(socket, :index, "main")

    content = ~E"""
      <span class="text-primary mr-2">
        <svg class="bi" width="12" height="12" fill="currentColor">
          <use xlink:href="<%= Routes.static_path(socket, "/images/bootstrap-icons.svg#chevron-left") %>"/>
        </svg>
      </span>

      <%= dgettext("stores", "Back") %>
    """

    live_patch(content, to: path, class: "h5")
  end

  def lock_version_input(form, %Store{lock_version: lock_version}) do
    hidden_input(form, :lock_version, value: lock_version)
  end

  def submit_button do
    "stores"
    |> dgettext("Save")
    |> submit(
      class: "btn btn-outline-info border border-info rounded-pill font-weight-semi-bold py-2",
      phx_disable_with: dgettext("stores", "Saving...")
    )
  end

  defp store_slug_hint do
    dgettext(
      "stores",
      "This is part of the store address, you can only use letters, underscores and numbers, don't use spaces!"
    )
  end

  defp image(socket, %Store{logo: nil} = store) do
    path = Routes.static_path(socket, "/images/store_default_logo.svg")

    img_tag(path,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid img-thumbnail"
    )
  end

  defp image(_socket, %Store{logo: logo} = store) do
    url = Tq2.LogoUploader.url({logo, store}, :thumb)

    set = %{
      url => "1x",
      Tq2.LogoUploader.url({logo, store}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid img-thumbnail"
    )
  end

  defp store_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :store_subdomain), url_config[:host]], ".")
    }
  end

  defp put_logo_on_params(params, socket, upload) do
    logo =
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

    params |> Map.put(to_string(upload), logo)
  end

  defp logo_input_class(form, field, upload) do
    class = "custom-file-input"

    case logo_errors(form, field, upload) do
      [] -> class
      _ -> "#{class} is-invalid"
    end
  end

  defp logo_label(upload) do
    case upload.entries |> List.first() do
      nil -> dgettext("stores", "Logo")
      entry -> entry.client_name
    end
  end

  defp logo_errors(form, field, upload) do
    upload_errors =
      for entry <- upload.entries, error <- upload_errors(upload, entry) do
        error_to_string(error)
      end

    case form.errors[field] do
      nil -> upload_errors
      _ -> upload_errors ++ translate_errors(form, field)
    end
  end

  defp logo_errors_tag(form, field, upload) do
    form
    |> logo_errors(field, upload)
    |> logo_errors_tag()
  end

  defp logo_errors_tag([]) do
    nil
  end

  defp logo_errors_tag(errors) do
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
end
