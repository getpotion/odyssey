defmodule Odyssey.EmailStub do
  @moduledoc """
  Stub implementation for email-related functionality in tests.
  """
  @behaviour Odyssey.Email.Behaviour

  def send_verification_email(_email, _url), do: :ok
  def send_2fa_recovery_email(_email, _token), do: :ok

  # Override Bamboo's deliver_later to prevent actual delivery attempts
  def deliver_later(_email), do: :ok
end
