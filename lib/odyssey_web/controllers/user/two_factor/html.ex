defmodule OdysseyWeb.User.TwoFactor.HTML do
  @moduledoc """
  Handles HTML templates and views for two-factor authentication pages.
  Embeds templates from the html directory for 2FA-related views.
  """

  use OdysseyWeb, :html

  embed_templates "html/*"
end
