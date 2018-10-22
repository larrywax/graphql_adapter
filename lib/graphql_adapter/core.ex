defmodule GraphqlAdapter.Core do
  @moduledoc """
  Documentation for GraphqlAdapter.
  """

  @http_options Application.get_env(:graphql_adapter, :http_options) ||
                  [
                    timeout: 1_000,
                    recv_timeout: 16_000
                  ]

  @http_headers Application.get_env(:graphql_adapter, :headers)

  @max_attempts Application.get_env(:graphql_adapter, :max_attempts) || 3

  @doc """
  Invoca la query graphql.
  ritorna `{:ok, valore}` o `{:error, ragione}`
  """
  @spec call(String.t(), String.t(), map()) :: {:ok, any()} | {:error, String.t()}
  def call(graphql_url, query, variables) do
    call(graphql_url, query, @http_headers, @http_options, variables)
  end

  @spec call(String.t(), String.t(), map() | Keyword.t(), map()) ::
          {:ok, any()} | {:error, String.t()}
  def call(graphql_url, query, headers, variables) when is_map(headers) do
    call(graphql_url, query, headers, @http_options, variables)
  end

  def call(graphql_url, query, options, variables) do
    call(graphql_url, query, @http_headers, options, variables)
  end

  @spec call(String.t(), String.t(), map(), Keyword.t(), map()) ::
          {:ok, any()} | {:error, String.t()}
  def call(graphql_url, query, headers, options, variables) do
    query
    |> encode_query(variables)
    |> retry(fn query ->
      query
      |> post(graphql_url, headers, options)
      |> handle_response()
    end)
  end

  @spec retry(any(), (any -> {:error, String.t()} | {:ok, any()})) ::
          {:error, String.t()} | {:ok, any()}
  defp retry(arg, fun) do
    retry(arg, fun, 3)
  end

  @spec retry(any(), (any -> {:error, String.t()} | {:ok, any()}), pos_integer()) ::
          {:error, String.t()} | {:ok, any()}
  defp retry(arg, fun, 1) do
    fun.(arg)
  end

  defp retry(arg, fun, n) do
    case fun.(arg) do
      {:error, _reason} ->
        Process.sleep(500)
        retry(arg, fun, n - 1)

      val ->
        val
    end
  end

  defp post(data, graphql_url, headers, options),
    do: HTTPoison.post(graphql_url, data, headers, options)

  @spec encode_query(String.t(), map()) :: String.t()
  defp encode_query(query, variables),
    do: Poison.encode!(%{query: String.trim(query), variables: Poison.encode!(variables)})

  @spec handle_response(
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
        ) :: {:ok, any()} | {:error, String.t()}
  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}) do
    body_string
    |> Poison.decode(keys: :atoms)
    |> response_has_errors()
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: code, body: body}}) do
    {:error, "bad response code #{code}: #{body}"}
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "HTTP error #{reason}"}
  end

  @spec response_has_errors({:ok, %{errors: any()} | %{data: any()}} | {:error, any()}) ::
          {:ok, any()} | {:error, String.t()}
  defp response_has_errors({:error, reason}) do
    {:error, "Failed to decode Graphql response #{inspect(reason)}"}
  end

  defp response_has_errors({:ok, %{errors: errors}}) do
    {:error, "Failed to decode Graphql response #{inspect(errors)}"}
  end

  defp response_has_errors({:ok, %{data: data}}), do: {:ok, data}
end
