defmodule AuthManager.Accounts.User do
  @moduledoc """
  Esquema que representa a un usuario en el sistema.
  Hereda los campos personales del esquema Person.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AuthManager.Authorization.{UserRole, UserPermission}

  use AuthManager.Accounts.Person

  schema "users" do
    # Campos de autenticación
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :is_active, :boolean, default: true
    field :last_login, :utc_datetime

    # Campos comunes para datos personales
    person_fields()

    # Relaciones
    has_many :user_roles, UserRole
    has_many :roles, through: [:user_roles, :role]
    has_many :user_permissions, UserPermission
    has_many :permissions, through: [:user_permissions, :permission]

    timestamps()
  end

  @doc """
  Changeset para crear un nuevo usuario.
  """
  def create_changeset(user, attrs) do
    user
    |> person_changeset(attrs)
    |> cast(attrs, [:username, :email, :password, :is_active])
    |> validate_required([:username, :email, :password])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe ser un email válido")
    |> validate_length(:password, min: 8, message: "debe tener al menos 8 caracteres")
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  @doc """
  Changeset para actualizar un usuario existente.
  """
  def update_changeset(user, attrs) do
    user
    |> person_changeset(attrs)
    |> cast(attrs, [:username, :email, :is_active])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "debe ser un email válido")
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  @doc """
  Changeset para actualizar la contraseña de un usuario.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "debe tener al menos 8 caracteres")
    |> put_password_hash()
  end

  @doc """
  Actualiza el timestamp de último inicio de sesión.
  """
  def login_changeset(user) do
    change(user, last_login: DateTime.utc_now())
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
      _ ->
        changeset
    end
  end
end
