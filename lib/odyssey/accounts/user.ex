defmodule Odyssey.Accounts.User do
  @moduledoc """
  Ecto schema for Odyssey users, including registration, password hashing, and verification fields.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :user_id, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :email_verified_at, :naive_datetime
    field :verification_token, :string
    field :verification_token_expires_at, :naive_datetime
    field :two_factor_enabled, :boolean, default: false
    field :two_factor_secret, :string
    field :recovery_codes, {:array, :string}, default: []

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :email, :password])
    |> validate_required([:user_id, :email, :password])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_length(:password, min: 8)
    |> validate_length(:user_id, min: 3)
    |> unique_constraint(:user_id, message: "User ID already exists")
    |> unique_constraint(:email, message: "Email already exists")
    |> put_password_hash()
    |> put_verification_token()
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :user_id,
      :email,
      :email_verified_at,
      :verification_token,
      :verification_token_expires_at,
      :two_factor_enabled,
      :two_factor_secret,
      :recovery_codes
    ])
    |> validate_required([:user_id, :email])
    |> unique_constraint(:user_id)
    |> unique_constraint(:email)
  end

  def two_factor_changeset(user, attrs) do
    user
    |> cast(attrs, [:two_factor_enabled, :two_factor_secret, :recovery_codes])
    |> validate_required([:two_factor_enabled, :two_factor_secret])
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  defp put_verification_token(changeset) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    expires_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(24 * 60 * 60)
      |> NaiveDateTime.truncate(:second)

    changeset
    |> put_change(:verification_token, token)
    |> put_change(:verification_token_expires_at, expires_at)
    |> put_change(:email_verified_at, nil)
  end
end
