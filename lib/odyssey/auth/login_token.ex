defmodule Odyssey.Auth.LoginToken do
  @moduledoc """
  Handles login token operations for the polling mechanism.
  """

  # 5 minutes
  @token_ttl 300

  @doc """
  Generates a new login token ID.
  """
  def generate_token_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> binary_part(0, 16)
  end

  @doc """
  Stores a login token in the cache.
  """
  def store_token(token_id, user_id) do
    Cachex.put(
      :login_tokens,
      token_id,
      %{
        user_id: user_id,
        status: :pending,
        inserted_at: DateTime.utc_now()
      },
      ttl: @token_ttl
    )
  end

  @doc """
  Updates a login token status.
  """
  def update_token_status(token_id, status, token \\ nil) do
    case Cachex.get(:login_tokens, token_id) do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, data} ->
        updated_data =
          Map.merge(data, %{
            status: status,
            token: token,
            updated_at: DateTime.utc_now()
          })

        Cachex.put(:login_tokens, token_id, updated_data, ttl: @token_ttl)
    end
  end

  @doc """
  Gets a login token from the cache.
  """
  def get_token(token_id) do
    case Cachex.get(:login_tokens, token_id) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, data} -> {:ok, data}
    end
  end
end
