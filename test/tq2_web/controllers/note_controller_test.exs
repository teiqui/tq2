defmodule Tq2Web.NoteControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  @create_attrs %{
    title: "some title",
    body: "some body",
    publish_at: Date.utc_today()
  }
  @update_attrs %{
    title: "some updated title",
    body: "some updated body",
    publish_at: Date.utc_today()
  }
  @invalid_attrs %{
    title: nil,
    body: nil,
    publish_at: nil
  }

  def note_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, note} = Tq2.News.create_note(session, @create_attrs)

    %{note: note}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.note_path(conn, :index)),
          get(conn, Routes.note_path(conn, :new)),
          post(conn, Routes.note_path(conn, :create, %{})),
          get(conn, Routes.note_path(conn, :show, "123")),
          get(conn, Routes.note_path(conn, :edit, "123")),
          put(conn, Routes.note_path(conn, :update, "123", %{})),
          delete(conn, Routes.note_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "index" do
    setup [:note_fixture]

    @tag login_as: "test@user.com", login_role: "admin"
    test "lists all notes", %{conn: conn, note: note} do
      conn = get(conn, Routes.note_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Notes"
      assert response =~ note.title
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com", login_role: "admin"
    test "lists no notes", %{conn: conn} do
      conn = get(conn, Routes.note_path(conn, :index))

      assert html_response(conn, 200) =~ "you have no notes"
    end
  end

  describe "new note" do
    @tag login_as: "test@user.com", login_role: "admin"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.note_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "create note" do
    @tag login_as: "test@user.com", login_role: "admin"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.note_path(conn, :create), note: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.note_path(conn, :show, id)
    end

    @tag login_as: "test@user.com", login_role: "admin"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.note_path(conn, :create), note: @invalid_attrs

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "show" do
    setup [:note_fixture]

    @tag login_as: "test@user.com"
    test "show note", %{conn: conn, note: note} do
      conn = get(conn, Routes.note_path(conn, :show, note))
      response = html_response(conn, 200)

      assert response =~ note.body
    end
  end

  describe "edit note" do
    setup [:note_fixture]

    @tag login_as: "test@user.com", login_role: "admin"
    test "renders form for editing chosen note", %{conn: conn, note: note} do
      conn = get(conn, Routes.note_path(conn, :edit, note))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update note" do
    setup [:note_fixture]

    @tag login_as: "test@user.com", login_role: "admin"
    test "redirects when data is valid", %{conn: conn, note: note} do
      conn = put conn, Routes.note_path(conn, :update, note), note: @update_attrs

      assert redirected_to(conn) == Routes.note_path(conn, :show, note)
    end

    @tag login_as: "test@user.com", login_role: "admin"
    test "renders errors when data is invalid", %{conn: conn, note: note} do
      conn = put conn, Routes.note_path(conn, :update, note), note: @invalid_attrs

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "delete note" do
    setup [:note_fixture]

    @tag login_as: "test@user.com", login_role: "admin"
    test "deletes chosen note", %{conn: conn, note: note} do
      conn = delete(conn, Routes.note_path(conn, :delete, note))

      assert redirected_to(conn) == Routes.note_path(conn, :index)
    end
  end
end
