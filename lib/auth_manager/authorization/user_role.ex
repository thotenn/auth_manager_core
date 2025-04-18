defmodule AuthManager.Authorization.UserRole do
  @moduledoc """
  Esquema intermedio para la relación muchos a muchos entre usuarios y roles.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AuthManager.Accounts.User
  alias AuthManager.Authorization.Role

  schema "user_roles" do
    belongs_to :user, User
    belongs_to :role, Role
    field :assigned_by, :integer
    field :notes, :string

    timestamps()
  end

  @doc """
  Changeset para crear o actualizar una asignación de rol a usuario.
  """
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id, :assigned_by, :notes])
    |> validate_required([:user_id, :role_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:role_id)
    |> unique_constraint([:user_id, :role_id], name: :user_roles_user_id_role_id_index)
  end
end
