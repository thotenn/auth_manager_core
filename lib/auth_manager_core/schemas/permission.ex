defmodule AuthManagerCore.Schemas.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :parent_id, :integer

    many_to_many :roles, AuthManagerCore.Schemas.Role, join_through: "role_permissions"

    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :description, :parent_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
