defmodule Tq2Web.Shop.StoreLive do
  use Tq2Web, :live_view

  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2.{Accounts, Shops}
  alias Tq2.Shops.Store

  @impl true
  def mount(%{"section" => section}, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    store = Shops.get_store!(session.account)

    socket =
      socket
      |> allow_upload(:logo, accept: ~w(.jpg .jpeg .gif .png .webp))
      |> assign(
        changes: %{},
        section: section,
        session: session,
        store: store
      )
      |> build_default_shipping()
      |> add_changeset()

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
  def handle_event("validate", %{"store" => changes}, socket) do
    socket = socket |> assign(changes: changes)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  @impl true
  def handle_event(
        "add-shipping",
        _params,
        %{assigns: %{store: store, changes: changes}} = socket
      ) do
    shippings =
      changes
      |> current_shippings(store)
      |> Map.merge(new_shipping())

    socket =
      socket
      |> add_changes_with_shippings(shippings)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete-shipping",
        %{"id" => id},
        %{assigns: %{store: store, changes: changes}} = socket
      ) do
    shippings = current_shippings(changes, store)

    shippings =
      case Enum.find(shippings, fn {i, s} -> id in [s[:id], s["id"], i] end) do
        nil -> shippings
        {k, _} -> Map.delete(shippings, k)
      end

    socket =
      socket
      |> add_changes_with_shippings(shippings)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"store" => store_params},
        %{assigns: %{session: session, store: store}} = socket
      ) do
    store_params =
      store_params
      |> put_logo_on_params(socket, :logo)
      |> handle_shipping_params(socket)

    case Shops.update_store(session, store, store_params) do
      {:ok, store} ->
        socket =
          socket
          |> put_flash(:info, dgettext("stores", "Store updated successfully."))
          |> assign(store: store, changes: %{})
          |> add_changeset()

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

      <span class="h6 text-primary float-right mb-0">
        <i class="bi-chevron-right"></i>
      </span>
    """

    live_patch(content, to: path, class: "list-group-item list-group-item-action bg-light py-3")
  end

  defp link_to_main(socket) do
    path = Routes.store_path(socket, :index, "main")

    content = ~E"""
      <span class="h5 text-primary mr-2 mb-0 mt-n2">
        <i class="bi-chevron-left"></i>
      </span>

      <%= dgettext("stores", "Back") %>
    """

    live_patch(content, to: path, class: "h5 text-decoration-none")
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

  defp current_shippings(%{"configuration" => %{"shippings" => shippings}}, _store) do
    shippings || %{}
  end

  defp current_shippings(_changes, %{configuration: %{shippings: shippings}}) do
    (shippings || [])
    |> Enum.with_index()
    |> Map.new(fn {s, i} -> {"#{i}", Map.from_struct(s)} end)
  end

  defp current_shippings(_changes, _store), do: %{}

  defp add_changeset(
         %{assigns: %{changes: changes, session: %{account: account}, store: store}} = socket
       ) do
    changeset = Shops.change_store(account, store, changes)

    socket |> assign(:changeset, changeset)
  end

  defp handle_shipping_params(%{"configuration" => configuration} = params, %{
         assigns: %{section: "delivery"}
       }) do
    config =
      case configuration do
        %{"delivery" => "true"} ->
          # Add new shipping to get validated
          Map.put_new(configuration, "shippings", new_shipping())

        _ ->
          # Delete all shippings just in case
          Map.put_new(configuration, "shippings", %{})
      end

    Map.put(params, "configuration", config)
  end

  defp handle_shipping_params(params, _socket), do: params

  defp build_default_shipping(
         %{assigns: %{section: "delivery", store: %{configuration: configuration}}} = socket
       ) do
    changes =
      case configuration do
        %{shippings: [_ | _]} ->
          %{}

        nil ->
          %{"configuration" => %{"shippings" => new_shipping()}}

        config ->
          config =
            config
            |> Map.from_struct()
            |> Map.new(fn {k, v} -> {"#{k}", v} end)
            |> Map.merge(%{"shippings" => new_shipping()})

          %{"configuration" => config}
      end

    socket |> assign(changes: changes)
  end

  defp build_default_shipping(socket), do: socket

  defp new_shipping do
    %{"#{:os.system_time()}" => %{id: Ecto.UUID.generate()}}
  end

  defp id_for_shipping_field(sf) do
    sf.data.id || sf.params["id"] || sf.index
  end

  defp show_shippings_error(%{source: %{errors: [{:shippings, {msg, []}} | _]}}) do
    content_tag(:p, msg, class: "text-danger")
  end

  defp show_shippings_error(_), do: nil

  defp add_changes_with_shippings(
         %{assigns: %{changes: changes, store: store}} = socket,
         shippings
       ) do
    config =
      case changes["configuration"] do
        nil ->
          ((store.configuration && Map.from_struct(store.configuration)) || %{})
          |> Map.put(:shippings, shippings)
          |> Map.new(fn {k, v} -> {to_string(k), v} end)

        conf ->
          Map.put(conf, "shippings", shippings)
      end

    changes = changes |> Map.put("configuration", config)

    socket
    |> assign(changes: changes)
    |> add_changeset()
  end
end
