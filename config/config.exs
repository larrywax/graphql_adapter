# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :graphql_adapter,
  headers: %{
    "User-Agent" => "domain-microservice-dummy/#{Mix.Project.config()[:version]}",
    "Content-type" => "application/json"
  }
