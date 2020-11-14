defmodule Tq2Web.InputHelpersTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1]

  describe "input" do
    import Tq2Web.InputHelpers
    import Phoenix.HTML.Form, only: [form_for: 4]

    test "with default options", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name)
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "Name"
        assert input =~ "class=\"form-group\""
        assert input =~ "class=\"form-control\""
        ""
      end)
    end

    test "with custom wrapper options", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, nil, wrapper_html: [class: "test-wrapper-class"])
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "test-wrapper-class"
        assert input =~ "form-group"
        assert input =~ "form-control"
        refute input =~ "wrapper_html"
        ""
      end)
    end

    test "with custom input options", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, nil, input_html: [class: "test-input-class"])
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "test-input-class"
        assert input =~ "form-group"
        assert input =~ "form-control"
        refute input =~ "input_html"
        ""
      end)
    end

    test "with custom label options", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, "Test label", label_html: [class: "test-label-class"])
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "Test label"
        assert input =~ "test-label-class"
        refute input =~ "label_html"
        ""
      end)
    end

    test "with using option", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, nil, using: :password_input)
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "type=\"password\""
        refute input =~ "using"
        ""
      end)
    end

    test "with using textarea option", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, nil, using: :textarea)
          |> input_to_string()

        assert input =~ "<textarea"
        refute input =~ "using"
        ""
      end)
    end

    test "with collection option", %{conn: conn} do
      form_for(conn, "/", [as: :test], fn form ->
        input =
          form
          |> input(:name, nil, collection: [1, 2, 3])
          |> input_to_string()

        assert input =~ "<select"
        assert input =~ "<div class=\"form-group\">"
        assert input =~ "<option value=\"1\">1</option>"
        assert input =~ "<option value=\"2\">2</option>"
        assert input =~ "<option value=\"3\">3</option>"
        refute input =~ "collection"
        ""
      end)
    end

    test "with file input", %{conn: conn} do
      form_for(conn, "/", [as: :test, multipart: true], fn form ->
        input =
          form
          |> input(:file, nil, input_html: [class: "test-input-class"])
          |> input_to_string()

        assert input =~ "<input"
        assert input =~ "test-input-class"
        assert input =~ "form-group"
        assert input =~ "form-control-file"
        refute input =~ "input_html"
        ""
      end)
    end
  end

  defp input_to_string(input) do
    input
    |> html_escape()
    |> safe_to_string()
  end
end
