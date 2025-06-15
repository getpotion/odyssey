defmodule Odyssey.Accounts.Behaviour do
  @moduledoc """
  Defines the behaviour for the Accounts context, specifying required callbacks for user management.
  """
  @callback register_user(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  @callback verify_email(String.t()) :: {:ok, map()} | {:error, :invalid_token | :expired_token}
end
