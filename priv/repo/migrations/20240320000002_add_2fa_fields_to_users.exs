defmodule Odyssey.Repo.Migrations.Add2faFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :two_factor_enabled, :boolean, default: false
      add :two_factor_secret, :string
      add :recovery_codes, {:array, :string}, default: []
    end
  end
end
