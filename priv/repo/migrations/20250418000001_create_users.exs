defmodule AuthManagerCore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :name, :string
      add :active, :boolean, default: true
      add :last_login, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
