defmodule AuthManagerCore.Schemas.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :slug, :string
    field :description, :string

    many_to_many :users, AuthManagerCore.Schemas.User, join_through: "user_roles"
    many_to_many :permissions, AuthManagerCore.Schemas.Permission, join_through: "role_permissions"

    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
