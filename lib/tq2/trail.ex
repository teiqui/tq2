defmodule Tq2.Trail do
  def insert(struct_or_changeset, opts \\ []) do
    struct_or_changeset
    |> PaperTrail.insert(opts)
    |> extract_model()
  end

  def update(changeset, opts \\ []) do
    empty_changes = %{}

    # Skip version without changes
    # TODO: Remove after paper_trail solve this
    case changeset do
      %Ecto.Changeset{changes: ^empty_changes, valid?: true} ->
        {:ok, changeset.data}

      _ ->
        changeset
        |> PaperTrail.update(opts)
        |> extract_model()
    end
  end

  def delete(struct_or_changeset, opts \\ []) do
    struct_or_changeset
    |> PaperTrail.delete(opts)
    |> extract_model()
  end

  defp extract_model({:ok, %{model: model}}), do: {:ok, model}
  defp extract_model(error), do: error
end
