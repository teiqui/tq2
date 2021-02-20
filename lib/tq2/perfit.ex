defmodule Tq2.Perfit do
  alias Tq2.Accounts
  alias Tq2.Accounts.Session

  def create_contact(%Session{user: user} = session) do
    params = %{
      first_name: user.name,
      last_name: user.lastname,
      email: user.email
    }

    "contacts"
    |> post(params)
    |> handle_response(session)
  end

  defp handle_response(nil, _session), do: nil

  defp handle_response(%{"data" => %{"id" => id}}, session) do
    {:ok, _user} = Accounts.update_user(session, session.user, %{data: %{external_id: id}})
  end

  defp post(namespace, %{} = params) do
    json_params = params |> Jason.encode!()

    case HTTPoison.post(url(namespace), json_params, headers()) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, reason} ->
        Sentry.capture_message("Perfit Error", extra: %{reason: Map.from_struct(reason)})

        nil
    end
  end

  defp url(namespace) do
    endpoint = Application.get_env(:tq2, :perfit)[:endpoint]

    Enum.join([endpoint, namespace], "/")
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
