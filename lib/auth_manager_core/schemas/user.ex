defmodule AuthManagerCore.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date
    field :gender, :string
    field :identity_document, :string
    field :phone, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :username, :string
    field :is_active, :boolean, default: true
    field :last_login, :utc_datetime

    many_to_many :roles, AuthManagerCore.Schemas.Role, join_through: "user_roles"

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :birth_date, :gender, :identity_document, :phone, :address, :city, :state, :country, :postal_code, :username, :is_active, :last_login])
    |> validate_required([:email, :password, :username])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe tener un formato de email válido")
    |> validate_length(:password, min: 6, message: "debe tener al menos 6 caracteres")
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  # Changeset para actualización que no requiere contraseña
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :birth_date, :gender, :identity_document, :phone, :address, :city, :state, :country, :postal_code, :username, :is_active, :last_login])
    |> validate_required([:email, :username])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe tener un formato de email válido")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end