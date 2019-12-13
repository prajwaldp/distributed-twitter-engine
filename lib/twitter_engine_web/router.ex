defmodule TwitterEngineWeb.Router do
  use TwitterEngineWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # Disable CSRF token check
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterEngineWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/join", PageController, :join
    post "/tweets", PageController, :create_tweet
    post "/subscribe-to-user", PageController, :subscribe_to_user
    post "/subscribe-to-hashtag", PageController, :subscribe_to_hashtag
    post "/retweet", PageController, :retweet
    get "/search", PageController, :search
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterEngineWeb do
  #   pipe_through :api
  # end
end
