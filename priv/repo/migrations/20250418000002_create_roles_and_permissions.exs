defmodule AuthManagerCore.Repo.Migrations.CreateRolesAndPermissions do
  use Ecto.Migration

  def change do
    # Tabla de roles
    create table(:roles) do
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create unique_index(:roles, [:name])

    # Tabla de permisos
    create table(:permissions) do
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create unique_index(:permissions, [:name])

    # Tabla de usuarios_roles (relación muchos a muchos)
    create table(:users_roles, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role_id, references(:roles, on_delete: :delete_all), null: false
    end

    create unique_index(:users_roles, [:user_id, :role_id])

    # Tabla de roles_permissions (relación muchos a muchos)
    create table(:roles_permissions, primary_key: false) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
    end

    create unique_index(:roles_permissions, [:role_id, :permission_id])
  end
end
