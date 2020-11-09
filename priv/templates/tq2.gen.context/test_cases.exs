
  describe "<%= schema.plural %>" do
    setup [:create_session]

    alias <%= inspect schema.module %>

    @valid_attrs <%= inspect schema.params.create %>
    @update_attrs <%= inspect schema.params.update %>
    @invalid_attrs <%= inspect for {key, _} <- schema.params.create, into: %{}, do: {key, nil} %>

    defp create_session(_) do
      account = <%= inspect context.base_module %>.Repo.get_by!(<%= inspect context.base_module %>.Accounts.Account, name: "test_account")

      {:ok, session: %<%= inspect context.base_module %>.Accounts.Session{account: account}}
    end

    defp fixture(session, :<%= schema.singular %>, attrs \\ %{}) do
      <%= schema.singular %>_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, <%= schema.singular %>} = <%= inspect context.alias %>.create_<%= schema.singular %>(session, <%= schema.singular %>_attrs)

      <%= schema.singular %>
    end

    test "list_<%= schema.plural %>/2 returns all <%= schema.plural %>", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert <%= inspect context.alias %>.list_<%= schema.plural %>(session.account, %{}).entries == [<%= schema.singular %>]
    end

    test "get_<%= schema.singular %>!/2 returns the <%= schema.singular %> with given id", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, <%= schema.singular %>.id) == <%= schema.singular %>
    end

    test "create_<%= schema.singular %>/2 with valid data creates a <%= schema.singular %>", %{session: session} do
      assert {:ok, %<%= inspect schema.alias %>{} = <%= schema.singular %>} = <%= inspect context.alias %>.create_<%= schema.singular %>(session, @valid_attrs)<%= for {field, value} <- schema.params.create do %>
      assert <%= schema.singular %>.<%= field %> == @valid_attrs.<%= field %><% end %>
    end

    test "create_<%= schema.singular %>/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = <%= inspect context.alias %>.create_<%= schema.singular %>(session, @invalid_attrs)
    end

    test "update_<%= schema.singular %>/3 with valid data updates the <%= schema.singular %>", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert {:ok, <%= schema.singular %>} = <%= inspect context.alias %>.update_<%= schema.singular %>(session, <%= schema.singular %>, @update_attrs)
      assert %<%= inspect schema.alias %>{} = <%= schema.singular %><%= for {field, value} <- schema.params.update do %>
      assert <%= schema.singular %>.<%= field %> == @update_attrs.<%= field %><% end %>
    end

    test "update_<%= schema.singular %>/3 with invalid data returns error changeset", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert {:error, %Ecto.Changeset{}} = <%= inspect context.alias %>.update_<%= schema.singular %>(session, <%= schema.singular %>, @invalid_attrs)
      assert <%= schema.singular %> == <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, <%= schema.singular %>.id)
    end

    test "delete_<%= schema.singular %>/2 deletes the <%= schema.singular %>", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert {:ok, %<%= inspect schema.alias %>{}} = <%= inspect context.alias %>.delete_<%= schema.singular %>(session, <%= schema.singular %>)
      assert_raise Ecto.NoResultsError, fn -> <%= inspect context.alias %>.get_<%= schema.singular %>!(session.account, <%= schema.singular %>.id) end
    end

    test "change_<%= schema.singular %>/2 returns a <%= schema.singular %> changeset", %{session: session} do
      <%= schema.singular %> = fixture(session, :<%= schema.singular %>)

      assert %Ecto.Changeset{} = <%= inspect context.alias %>.change_<%= schema.singular %>(session.account, <%= schema.singular %>)
    end
  end
