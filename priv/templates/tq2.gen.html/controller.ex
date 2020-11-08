defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Controller do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, session) do
    page = <%= inspect context.alias %>.list_<%= schema.plural %>(session.account, params)

    render_index(conn, page)
  end

  def new(conn, _params, session) do
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(session.account, %<%= inspect schema.alias %>{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}, session) do
    case <%= inspect context.alias %>.create_<%= schema.singular %>(session, <%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        conn
        |> put_flash(:info, dgettext("<%= schema.plural %>", "<%= schema.human_singular %> created successfully."))
        |> redirect(to: Routes.<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, session) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, id)

    render(conn, "show.html", <%= schema.singular %>: <%= schema.singular %>)
  end

  def edit(conn, %{"id" => id}, session) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, id)
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(session.account, <%= schema.singular %>)

    render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
  end

  def update(conn, %{"id" => id, <%= inspect schema.singular %> => <%= schema.singular %>_params}, session) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, id)

    case <%= inspect context.alias %>.update_<%= schema.singular %>(session, <%= schema.singular %>, <%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        conn
        |> put_flash(:info, dgettext("<%= schema.plural %>", "<%= schema.human_singular %> updated successfully."))
        |> redirect(to: Routes.<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, session) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, id)
    {:ok, _<%= schema.singular %>} = <%= inspect context.alias %>.delete_<%= schema.singular %>(session, <%= schema.singular %>)

    conn
    |> put_flash(:info, dgettext("<%= schema.plural %>", "<%= schema.human_singular %> deleted successfully."))
    |> redirect(to: Routes.<%= schema.route_helper %>_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")
  defp render_index(conn, page) do
    render(conn, "index.html", <%= schema.plural %>: page.entries, page: page)
  end
end
