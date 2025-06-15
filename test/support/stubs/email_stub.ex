defmodule Odyssey.EmailStub do
  @moduledoc """
  Stub implementation for email-related functionality in tests.
  """
  @behaviour Odyssey.Email.Behaviour
  def send_verification_email(_email, _url), do: :ok
end
