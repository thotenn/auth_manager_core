defmodule AuthManager.Authorization.Role do
  @moduledoc """
  Esquema que representa un rol en el sistema.
  Los roles pueden tener padres, lo que permite herencia.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias AuthManager.Authorization.{Role, RolePermission, UserRole, RoleRole}

  schema "roles" do
    field :name, :string
    field :slug, :string
    field :description, :string

    # Relaciones entre roles (para herencia)
    has_many :parent_relations, RoleRole, foreign_key: :child_role_id
    has_many :parents, through: [:parent_relations, :parent_role]
    has_many :child_relations, RoleRole, foreign_key: :parent_role_id
    has_many :children, through: [:child_relations, :child_role]

    # Relaciones con permisos y usuarios
    has_many :role_permissions, RolePermission
    has_many :permissions, through: [:role_permissions, :permission]
    has_many :user_roles, UserRole
    has_many :users, through: [:user_roles, :user]

    timestamps()
  end

  @doc """
  Changeset para crear o actualizar un rol.
  """
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> generate_slug_if_empty()
    |> unique_constraint(:slug)
  end

  # Genera un slug basado en el nombre si no se proporciona.
  defp generate_slug_if_empty(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil -> changeset
          name ->
            slug = name
                   |> String.downcase()
                   |> String.replace(~r/[^a-z0-9]+/, "_")
                   |> String.trim("_")
            put_change(changeset, :slug, slug)
        end
      _ -> changeset
    end
  end

  @doc """
  Obtiene todos los roles padre recursivamente.
  """
  def get_all_parent_roles(repo, role_id) do
    parent_role_ids_query = from rr in RoleRole,
                            where: rr.child_role_id == ^role_id,
                            select: rr.parent_role_id

    parent_role_ids = repo.all(parent_role_ids_query)

    parent_roles = from r in Role,
                   where: r.id in ^parent_role_ids,
                   select: r

    repo.all(parent_roles)
    |> Enum.flat_map(fn parent_role ->
      [parent_role | get_all_parent_roles(repo, parent_role.id)]
    end)
  end

  @doc """
  Obtiene todos los roles hijo recursivamente.
  """
  def get_all_child_roles(repo, role_id) do
    child_role_ids_query = from rr in RoleRole,
                           where: rr.parent_role_id == ^role_id,
                           select: rr.child_role_id

    child_role_ids = repo.all(child_role_ids_query)

    child_roles = from r in Role,
                  where: r.id in ^child_role_ids,
                  select: r

    repo.all(child_roles)
    |> Enum.flat_map(fn child_role ->
      [child_role | get_all_child_roles(repo, child_role.id)]
    end)
  end
end
