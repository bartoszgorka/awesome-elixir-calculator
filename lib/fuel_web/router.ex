defmodule FuelWeb.Router do
  use FuelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FuelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", FuelWeb do
    pipe_through :browser

    live "/", FuelLive
  end
end
