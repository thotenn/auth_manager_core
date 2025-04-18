defmodule AuthManager.Authorization.Permission do
  @moduledoc """
  Esquema que representa un permiso en el sistema.
  Los permisos pueden tener padres, lo que permite herencia.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias AuthManager.Authorization.{Permission, RolePermission, UserPermission}

  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :description, :string

    # Auto-referencia para permisos padre
    belongs_to :parent, Permission
    has_many :children, Permission, foreign_key: :parent_id

    # Relaciones con roles y usuarios
    has_many :role_permissions, RolePermission
    has_many :roles, through: [:role_permissions, :role]
    has_many :user_permissions, UserPermission
    has_many :users, through: [:user_permissions, :user]

    timestamps()
  end

  @doc """
  Changeset para crear o actualizar un permiso.
  """
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :description, :parent_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> generate_slug_if_empty()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:parent_id)
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
  Obtiene todos los permisos padre recursivamente.
  """
  def get_all_parents(repo, permission_id) do
    query = from p in Permission,
            where: p.id == ^permission_id,
            select: %{id: p.id, parent_id: p.parent_id}

    case repo.one(query) do
      nil -> []
      %{parent_id: nil} -> []
      %{parent_id: parent_id} ->
        parent = repo.get(Permission, parent_id)
        [parent | get_all_parents(repo, parent_id)]
    end
  end

  @doc """
  Obtiene todos los permisos hijos recursivamente.
  """
  def get_all_children(repo, permission_id) do
    children_query = from p in Permission,
                     where: p.parent_id == ^permission_id

    repo.all(children_query)
    |> Enum.flat_map(fn child ->
      [child | get_all_children(repo, child.id)]
    end)
  end
end
