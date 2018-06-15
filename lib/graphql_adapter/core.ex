defmodule GraphqlAdapter.Core do
  @moduledoc """
  Documentation for GraphqlAdapter.
  """

  require Logger

  @http_options [
    timeout: 1_000,
    recv_timeout: 16_000
  ]

  @http_headers Application.get_env(:graphql_adapter, __MODULE__)[:headers]

  @doc """
  Invoca la query graphql.
  ritorna `{:ok, valore}` o `{:error, ragion}`
  """
  @spec call(String.t(), String.t(), map()) :: {:ok, any()} | {:error, String.t()}
  def call(graphql_url, query, variables \\ %{}) do
    query
    |> encode_query(variables)
    |> retry(fn query ->
      query
      |> post(graphql_url)
      |> handle_response()
    end)
  end

  @spec retry(any(), (any -> {:error, String.t()} | {:ok, any()})) ::
          {:error, String.t()} | {:ok, any()}
  @spec retry(any(), (any -> {:error, String.t()} | {:ok, any()}), pos_integer()) ::
          {:error, String.t()} | {:ok, any()}
  def retry(arg, fun) do
    retry(arg, fun, 3)
  end

  def retry(arg, fun, 1) do
    fun.(arg)
  end

  def retry(arg, fun, n) do
    case fun.(arg) do
      {:error, _reason} ->
        Process.sleep(500)
        retry(arg, fun, n - 1)

      val ->
        val
    end
  end

  defp post(data, graphql_url),
    do: HTTPoison.post(graphql_url, data, @http_headers, @http_options)

  @spec encode_query(String.t(), map()) :: String.t()
  defp encode_query(query, variables),
    do: Poison.encode!(%{query: String.trim(query), variables: Poison.encode!(variables)})

  @spec handle_response(
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
        ) :: {:ok, map()} | {:ok, list()} | {:ok, nil} | {:error, String.t()}
  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}) do
    body_string
    |> Poison.decode(keys: :atoms)
    |> response_has_errors()
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: code, body: message}}) do
    Logger.warn(
      "response error #{code} #{message}",
      code: code,
      message: message
    )

    {:error, "bad response code #{code}: #{message}"}
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    Logger.warn("HTTP error #{reason}", reason: reason)
    {:error, reason}
  end

  @spec response_has_errors({:ok, map()} | {:error, any()}) ::
          {:ok, nil} | {:ok, String.t()} | {:error, String.t()}
  defp response_has_errors({:error, reason}) do
    Logger.warn("Failed to decode Graphql response", reason: inspect(reason))
    {:error, inspect(reason)}
  end

  defp response_has_errors({:ok, %{errors: reason}}) do
    Logger.warn("Failed to decode Graphql response", reason: inspect(reason))
    {:error, inspect(reason)}
  end

  defp response_has_errors({:ok, %{data: data}}), do: {:ok, data}
end
