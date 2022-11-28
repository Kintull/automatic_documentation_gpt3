defmodule AuDoc.Gpt3APIClient do
  @moduledoc false
  @gpt3_auth_token Application.compile_env(:au_doc, :gpt3_auth_token)

  @spec complete_input(binary, list(tuple)) :: binary
  def complete_input(input, opts \\ []) do
    instruction = opts[:instruction] || ""
    max_tokens = opts[:max_tokens] || 10
    temperature = opts[:temperature] || 0

    gpt3_url = "https://api.openai.com/v1/completions"

    headers = %{
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{@gpt3_auth_token}"
    }

    data = %{
      "model" => "text-davinci-003",
      "prompt" => input <> instruction,
      "temperature" => temperature,
      "max_tokens" => max_tokens
    }

    {:ok, response} =
      HTTPoison.post(gpt3_url, Jason.encode!(data), headers,
        timeout: 100_000,
        recv_timeout: 100_000
      )

    handle_response(response)
  end

  defp handle_response(%{status_code: 200, body: body}) do
    parsed_response = Jason.decode!(body)
    parsed_response["choices"] |> Enum.at(0) |> Access.get("text") |> String.trim()
  end

  defp handle_response(%{status_code: _, body: body}) do
    IO.inspect(body)
    "Error: invalid response code from gpt3"
  end

  defp handle_response(_) do
    "Error: timeout from gpt3"
  end
end
