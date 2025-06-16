defmodule OdysseyWeb.Page.Controller do
  @moduledoc """
  Handles page rendering for the main application pages.
  Provides the home page endpoint with custom layout rendering.
  """

  use OdysseyWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
