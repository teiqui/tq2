defmodule Tq2.Perfit do
  alias Tq2.Accounts
  alias Tq2.Accounts.{Session, User}

  def create_contact(%Session{user: user} = session) do
    lists = Application.get_env(:tq2, :perfit)[:new_contact_lists]

    params = %{
      first_name: user.name,
      last_name: user.lastname,
      email: user.email,
      lists: lists
    }

    "contacts"
    |> post(params)
    |> handle_response(session)
  end

  def update_contact(%Session{user: %{data: %{external_id: _}} = user}, attrs) do
    put("contacts", user, attrs)
  end

  def update_contact(_session, _attrs), do: nil

  defp handle_response(nil, _session), do: nil

  defp handle_response(%{"data" => %{"id" => id}}, session) do
    {:ok, _user} = Accounts.update_user(session, session.user, %{data: %{external_id: id}})
  end

  defp post(namespace, %{} = params) do
    json_params = params |> Jason.encode!()

    namespace
    |> url()
    |> HTTPoison.post(json_params, headers())
    |> handle_http_response()
  end

  defp put(namespace, %User{data: %{external_id: external_id}}, %{} = params) do
    json_params = params |> Jason.encode!()

    namespace
    |> url(external_id)
    |> HTTPoison.put(json_params, headers())
    |> handle_http_response()
  end

  defp handle_http_response({:ok, response}) do
    Jason.decode!(response.body)
  end

  defp handle_http_response({:error, reason}) do
    Sentry.capture_message("Perfit error", extra: %{reason: Map.from_struct(reason)})

    nil
  end

  defp url(namespace) do
    endpoint = Application.get_env(:tq2, :perfit)[:endpoint]

    Enum.join([endpoint, namespace], "/")
  end

  defp url(namespace, resource_id) do
    Enum.join([url(namespace), resource_id], "/")
  end

  defp headers do
    api_key = Application.get_env(:tq2, :perfit)[:api_key]

    [
      Authorization: "Bearer #{api_key}",
      Accept: "application/json; charset=utf-8",
      "Content-Type": "application/json"
    ]
  end
end
