defmodule AuthManager.Authorization.RoleRole do
  @moduledoc """
  Esquema intermedio para la relación de herencia entre roles (padres e hijos).
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AuthManager.Authorization.Role

  schema "role_roles" do
    belongs_to :parent_role, Role
    belongs_to :child_role, Role
    field :assigned_by, :integer
    field :notes, :string

    timestamps()
  end

  @doc """
  Changeset para crear o actualizar una relación entre roles.
  """
  def changeset(role_role, attrs) do
    role_role
    |> cast(attrs, [:parent_role_id, :child_role_id, :assigned_by, :notes])
    |> validate_required([:parent_role_id, :child_role_id])
    |> foreign_key_constraint(:parent_role_id)
    |> foreign_key_constraint(:child_role_id)
    |> validate_different_roles()
    |> validate_no_circular_dependency()
    |> unique_constraint([:parent_role_id, :child_role_id],
        name: :role_roles_parent_role_id_child_role_id_index)
  end

  # Valida que un rol no pueda ser su propio padre.
  defp validate_different_roles(changeset) do
    parent_id = get_field(changeset, :parent_role_id)
    child_id = get_field(changeset, :child_role_id)

    if parent_id == child_id do
      add_error(changeset, :child_role_id, "no puede ser igual al rol padre")
    else
      changeset
    end
  end

  # Valida que no existan dependencias circulares entre roles.
  defp validate_no_circular_dependency(changeset) do
    parent_id = get_field(changeset, :parent_role_id)
    child_id = get_field(changeset, :child_role_id)

    if parent_id && child_id do
      repo = Application.get_env(:auth_manager, :repo)

      # Comprobar si el rol hijo es ya un ancestro del rol padre
      parent_ancestors = Role.get_all_parent_roles(repo, parent_id)

      if Enum.any?(parent_ancestors, fn role -> role.id == child_id end) do
        add_error(changeset, :child_role_id, "crear esta relación resultaría en una dependencia circular")
      else
        changeset
      end
    else
      changeset
    end
  end
end
