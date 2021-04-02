defmodule Tq2.NewsTest do
  use Tq2.DataCase

  alias Tq2.News

  describe "notes" do
    setup [:create_session]

    alias Tq2.News.Note

    @valid_attrs %{
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

    defp create_session(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    defp fixture(session, :note, attrs \\ %{}) do
      note_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, note} = News.create_note(session, note_attrs)

      note
    end

    test "list_notes/1 returns all notes", %{session: session} do
      note = fixture(session, :note)

      assert News.list_notes(%{}).entries == [note]
    end

    test "get_note!/1 returns the note with given id", %{session: session} do
      note = fixture(session, :note)

      assert News.get_note!(note.id) == note
    end

    test "create_note/2 with valid data creates a note and notifies", %{session: session} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      assert {:ok, %Note{id: note_id} = note} = News.create_note(session, @valid_attrs)
      assert note.body == @valid_attrs.body
      assert note.publish_at == @valid_attrs.publish_at
      assert note.title == @valid_attrs.title

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      assert %{args: ["new_note", ^note_id], class: Tq2.Workers.NotificationsJob} =
               List.first(jobs)
    end

    test "create_note/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = News.create_note(session, @invalid_attrs)
    end

    test "update_note/3 with valid data updates the note", %{session: session} do
      note = fixture(session, :note)

      assert {:ok, note} = News.update_note(session, note, @update_attrs)
      assert %Note{} = note
      assert note.body == @update_attrs.body
      assert note.publish_at == @update_attrs.publish_at
      assert note.title == @update_attrs.title
    end

    test "update_note/3 with invalid data returns error changeset", %{session: session} do
      note = fixture(session, :note)

      assert {:error, %Ecto.Changeset{}} = News.update_note(session, note, @invalid_attrs)
      assert note == News.get_note!(note.id)
    end

    test "delete_note/2 deletes the note", %{session: session} do
      note = fixture(session, :note)

      assert {:ok, %Note{}} = News.delete_note(session, note)
      assert_raise Ecto.NoResultsError, fn -> News.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset", %{session: session} do
      note = fixture(session, :note)

      assert %Ecto.Changeset{} = News.change_note(note)
    end
  end
end
