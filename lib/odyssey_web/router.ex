defmodule OdysseyWeb.Router do
  use OdysseyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OdysseyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug OdysseyWeb.Auth.Pipeline
  end

  scope "/", OdysseyWeb do
    pipe_through :browser

    get "/", Page.Controller, :home
    post "/users/register", User.Controller, :register
    get "/users/verify/:token", User.Controller, :verify
  end

  scope "/", OdysseyWeb do
    pipe_through [:browser, :auth]

    get "/users/2fa/setup", User.TwoFactor.Controller, :setup
    post "/users/2fa/setup/verify", User.TwoFactor.Controller, :verify_setup
    get "/users/2fa", User.TwoFactor.Controller, :verify
    post "/users/2fa/verify", User.TwoFactor.Controller, :verify_code
  end

  scope "/v1/api", OdysseyWeb.API.V1 do
    pipe_through :api

    post "/login", User.Controller, :login_init
    get "/login/poll", User.Controller, :login_poll
    get "/login/poll/:token_id", User.Controller, :login_poll
    post "/login/verify-2fa", User.Controller, :verify_2fa
  end

  # Other scopes may use custom stacks.
  # scope "/api", OdysseyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:odyssey, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OdysseyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
