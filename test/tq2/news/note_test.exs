defmodule Tq2.News.NoteTest do
  use Tq2.DataCase, async: true

  describe "note" do
    alias Tq2.News.Note

    @valid_attrs %{
      title: "some title",
      body: "some body",
      publish_at: Date.utc_today()
    }
    @invalid_attrs %{
      title: nil,
      body: nil,
      publish_at: nil
    }

    test "changeset with valid attributes" do
      changeset = Note.changeset(%Note{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Note.changeset(%Note{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:title, String.duplicate("a", 256))

      changeset = Note.changeset(%Note{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).title
    end
  end
end
