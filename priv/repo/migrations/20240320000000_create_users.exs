defmodule Odyssey.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_id, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :email_verified_at, :naive_datetime
      add :verification_token, :string
      add :verification_token_expires_at, :naive_datetime

      timestamps()
    end

    create unique_index(:users, [:user_id])
    create unique_index(:users, [:email])
    create index(:users, [:verification_token])
  end
end
