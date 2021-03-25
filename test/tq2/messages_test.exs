defmodule Tq2.MessagesTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_order: 1]

  alias Tq2.Messages

  describe "comments" do
    setup [:create_order]

    alias Tq2.Messages.Comment

    @valid_attrs %{
      body: "some body",
      originator: "user",
      status: "created",
      order_id: "1"
    }
    @update_attrs %{
      body: "some updated body",
      originator: "customer",
      status: "delivered",
      order_id: "1"
    }
    @invalid_attrs %{
      body: nil,
      originator: nil,
      status: nil,
      order_id: nil
    }

    defp fixture(:comment, attrs) do
      comment_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, comment} = Messages.create_comment(comment_attrs)

      comment
    end

    test "list_comments/1 returns all comments for an order", %{order: order} do
      comment = fixture(:comment, %{order_id: order.id})

      assert Enum.map(Messages.list_comments(comment.order_id), & &1.id) == [comment.id]
    end

    test "get_comment!/1 returns the comment with given id", %{order: order} do
      comment = fixture(:comment, %{order_id: order.id})

      assert Messages.get_comment!(comment.id).id == comment.id
    end

    test "create_comment/1 with valid data creates a comment", %{order: order} do
      assert {:ok, %Comment{} = comment} =
               Messages.create_comment(%{@valid_attrs | order_id: order.id})

      assert comment.body == @valid_attrs.body
      assert comment.originator == @valid_attrs.originator
      assert comment.status == @valid_attrs.status
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment", %{order: order} do
      comment = fixture(:comment, %{order_id: order.id})

      assert {:ok, comment} =
               Messages.update_comment(comment, %{@update_attrs | order_id: order.id})

      assert %Comment{} = comment
      assert comment.body == @update_attrs.body
      assert comment.originator == @update_attrs.originator
      assert comment.status == @update_attrs.status
    end

    test "update_comment/2 with invalid data returns error changeset", %{order: order} do
      comment = fixture(:comment, %{order_id: order.id})

      assert {:error, %Ecto.Changeset{}} = Messages.update_comment(comment, @invalid_attrs)
      assert comment.body == Messages.get_comment!(comment.id).body
      refute comment.body == @invalid_attrs.body
    end

    test "change_comment/1 returns a comment changeset", %{order: order} do
      comment = fixture(:comment, %{order_id: order.id})

      assert %Ecto.Changeset{} = Messages.change_comment(comment)
    end

    test "subscription/1 annotates process for notifications", %{order: order} do
      Messages.subscribe(order)

      _comment = fixture(:comment, %{order_id: order.id})

      assert_received {:comment_created, _comment}
    end
  end
end
