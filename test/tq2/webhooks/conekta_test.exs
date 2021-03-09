defmodule Tq2.Webhooks.ConektaTest do
  use Tq2.DataCase, async: true

  describe "webhooks" do
    alias Tq2.Webhooks.Conekta

    @valid_attrs %{
      name: "conekta",
      payload: %{"user_id" => "123"}
    }

    @invalid_attrs %{
      name: nil,
      payload: nil
    }

    test "changeset with valid attributes" do
      changeset = Conekta.changeset(%Conekta{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Conekta.changeset(%Conekta{}, @invalid_attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).payload
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
