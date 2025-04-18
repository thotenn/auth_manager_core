defmodule AuthManager.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      # Campos personales (heredados de Person)
      add :first_name, :string
      add :last_name, :string
      add :birth_date, :date
      add :gender, :string
      add :identity_document, :string
      add :phone, :string
      add :address, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string

      # Campos de autenticación
      add :username, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :is_active, :boolean, default: true
      add :last_login, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
    create index(:users, [:is_active])
  end
end
