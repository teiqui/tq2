defmodule Tq2Web.NoteViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.NoteView
  alias Tq2.News
  alias Tq2.News.Note

  import Phoenix.View
  import Phoenix.HTML, only: [safe_to_string: 1]

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "renders index.html", %{conn: conn} do
    page = %Scrivener.Page{total_pages: 1, page_number: 1}

    notes = [
      %Note{id: "1", title: "Some title", body: "Some body", publish_at: Date.utc_today()},
      %Note{id: "2", title: "Other title", body: "Other body", publish_at: Date.utc_today()}
    ]

    content = render_to_string(NoteView, "index.html", conn: conn, notes: notes, page: page)

    for note <- notes do
      assert String.contains?(content, note.title)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = News.change_note(%Note{})
    content = render_to_string(NoteView, "new.html", conn: conn, changeset: changeset)

    assert String.contains?(content, "New note")
  end

  test "renders edit.html", %{conn: conn} do
    note = note()
    changeset = News.change_note(note)

    content =
      render_to_string(NoteView, "edit.html",
        conn: conn,
        note: note,
        changeset: changeset
      )

    assert String.contains?(content, note.title)
  end

  test "renders show.html", %{conn: conn} do
    note = note()
    session = %Tq2.Accounts.Session{}

    content =
      render_to_string(NoteView, "show.html", conn: conn, note: note, current_session: session)

    assert String.contains?(content, note.title)
  end

  test "link to show", %{conn: conn} do
    note = note()

    content =
      conn
      |> NoteView.link_to_show(note)
      |> safe_to_string()

    assert content =~ note.id
    assert content =~ "href"
  end

  test "link to edit", %{conn: conn} do
    note = note()

    content =
      conn
      |> NoteView.link_to_edit(note)
      |> safe_to_string()

    assert content =~ note.id
    assert content =~ "href"
  end

  test "link to delete", %{conn: conn} do
    note = note()

    content =
      conn
      |> NoteView.link_to_delete(note)
      |> safe_to_string()

    assert content =~ note.id
    assert content =~ "href"
    assert content =~ "delete"
  end

  defp note do
    %Note{id: "1", title: "Some title", body: "Some body", publish_at: Date.utc_today()}
  end
end
