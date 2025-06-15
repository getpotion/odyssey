defmodule Odyssey.Factory do
  @moduledoc """
  Factory module for creating test data.
  """

  alias Odyssey.Accounts.User
  alias Odyssey.Repo

  @doc """
  Inserts a user into the database with the given attributes.
  If attributes are not provided, default values are generated using Faker.
  """
  def insert(:user, attrs \\ %{}) do
    default_attrs = %{
      user_id: Faker.UUID.v4(),
      email: Faker.Internet.email(),
      password: Faker.String.base64(12)
    }

    attrs = Map.merge(default_attrs, Map.new(attrs))

    user =
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert!()

    # Patch after insert for fields not allowed in registration_changeset
    update_attrs =
      attrs
      |> Map.take([
        :verification_token,
        :verification_token_expires_at,
        :recovery_codes,
        :two_factor_enabled,
        :two_factor_secret
      ])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.into(%{})

    if map_size(update_attrs) > 0 do
      user
      |> Ecto.Changeset.change(update_attrs)
      |> Repo.update!()
    else
      user
    end
  end

  @doc """
  Returns a factory function for creating a user with default attributes.
  """
  def user_factory do
    %Odyssey.Accounts.User{
      user_id: Faker.UUID.v4(),
      email: Faker.Internet.email(),
      password: Faker.String.base64(12),
      password_hash: Bcrypt.hash_pwd_salt(Faker.String.base64(12)),
      email_verified_at: nil,
      verification_token: "token-#{System.unique_integer()}",
      verification_token_expires_at: nil,
      two_factor_enabled: false,
      two_factor_secret: nil,
      recovery_codes: []
    }
  end
end
