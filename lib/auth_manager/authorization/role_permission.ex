defmodule AuthManager.Authorization.RolePermission do
  @moduledoc """
  Esquema intermedio para la relación muchos a muchos entre roles y permisos.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AuthManager.Authorization.{Role, Permission}

  schema "role_permissions" do
    belongs_to :role, Role
    belongs_to :permission, Permission
    field :assigned_by, :integer
    field :notes, :string

    timestamps()
  end

  @doc """
  Changeset para crear o actualizar una asignación de permiso a rol.
  """
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id, :assigned_by, :notes])
    |> validate_required([:role_id, :permission_id])
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:permission_id)
    |> unique_constraint([:role_id, :permission_id], name: :role_permissions_role_id_permission_id_index)
  end
end
