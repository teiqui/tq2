defmodule Tq2.Messages.CommentTest do
  use Tq2.DataCase, async: true

  describe "subscription customer" do
    alias Tq2.Messages.Comment

    @valid_attrs %{
      body: "some body",
      originator: "user",
      status: "created",
      order_id: "1"
    }
    @invalid_attrs %{
      body: nil,
      originator: nil,
      status: nil,
      order_id: nil
    }

    test "changeset with valid attributes" do
      changeset = Comment.changeset(%Comment{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Comment.changeset(%Comment{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "invalid")
        |> Map.put(:originator, "invalid")

      changeset = Comment.changeset(%Comment{}, attrs)

      assert "is invalid" in errors_on(changeset).status
      assert "is invalid" in errors_on(changeset).originator
    end
  end
end
