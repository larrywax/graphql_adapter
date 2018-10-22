# GraphqlAdapter

Adapter for graphQL between PoisonHTTP and Absinthe 

## Motivation

We noticed that the same glue code is used in many elixir project, this library is used to put together HttpPoison, Poison and pass the results to Absynthe. This version also has a retry mechanism.

## Installation

Add in  `mix.exs` the following line: 

```elixir
{:graphql_adapter, git: "git@github.com:primait/graphql_adapter.git", branch: "master"}
```

## Usage

First add to config.exs the configuration for the headers:

```elixir
config :graphql_adapter,
       headers: %{
         "User-Agent" => "domain-microservice-name/#{Mix.Project.config()[:version]}",
         "Content-type" => "application/json"
       },
       http_options: [timeout: 1_000, recv_timeout: 16_000],
       max_attempts: 3
```

In the resolver file just import and use the main API entry point, `call` 

```elixir
  alias GraphqlAdapter.Core, as: Graphql

  @app_url "#{Application.get_env(:backend, :app)[:base_url]}/graphql"
  
    #later
  
  def do_request(%{request_param: param}, _info) do
    @app_url
    |> Graphql.call(@graphql_query, %{request_param: param})
    |> case do
         {:ok, request} ->
           {:ok, Map.get(request, :response, %{})}
  
         error ->
           error
      end
  end
```

```elixir
  def do_request(%{request_param: param}, _info) do
    @app_url
    |> Graphql.call(@graphql_query, %{"Content-type" => "application/json"}, %{request_param: param})
    |> case do
         {:ok, request} ->
           {:ok, Map.get(request, :response, %{})}
  
         error ->
           error
      end
  end
```
API returns 2 kind of values `%{:ok, map_or_list }` or `%{:error, cause}`
