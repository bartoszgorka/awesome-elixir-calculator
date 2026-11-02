defmodule Fuel.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # needed by LiveView sockets and dev live reload
      {Phoenix.PubSub, name: Fuel.PubSub},
      FuelWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Fuel.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    FuelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
