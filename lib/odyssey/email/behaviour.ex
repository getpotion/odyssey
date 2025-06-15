defmodule Odyssey.Email.Behaviour do
  @moduledoc """
  Behaviour for email delivery functionality.
  """

  @callback send_verification_email(String.t(), String.t()) :: :ok | {:error, term()}
end
