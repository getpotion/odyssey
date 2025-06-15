defmodule Odyssey.Accounts.TwoFactor.Behaviour do
  @moduledoc """
  Defines the behaviour for two-factor authentication operations, specifying required callbacks.
  """
  @callback generate_totp_secret() :: {String.t(), String.t()}
  @callback verify_totp_code(String.t(), String.t()) :: boolean
  @callback generate_recovery_codes() :: [String.t()]
  @callback enable_2fa(map, String.t(), [String.t()]) :: {:ok, map} | {:error, Ecto.Changeset.t()}
  @callback verify_recovery_code(map, String.t()) :: :ok | :error
end
