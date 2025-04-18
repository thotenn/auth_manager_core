defmodule AuthManagerCore.Auth do
  @moduledoc """
  Contexto de autenticación que maneja la creación y autenticación de usuarios.
  """

  alias AuthManagerCore.Repo
  alias AuthManagerCore.Schemas.User
  alias AuthManagerCore.Schemas.Role
  alias AuthManagerCore.Schemas.Permission

  import Ecto.Query

  @doc """
  Crea un nuevo usuario.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza un usuario existente.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Elimina un usuario.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Obtiene un usuario por su ID.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Obtiene un usuario por su email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Autentica a un usuario con su email y contraseña.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        # Previene timing attacks
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  @doc """
  Crea un nuevo rol.
  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Asigna un rol a un usuario.
  """
  def assign_role_to_user(%User{} = user, %Role{} = role) do
    user
    |> Repo.preload(:roles)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:roles, [role | user.roles])
    |> Repo.update()
  end

  @doc """
  Crea un nuevo permiso.
  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Asigna un permiso a un rol.
  """
  def assign_permission_to_role(%Role{} = role, %Permission{} = permission) do
    role
    |> Repo.preload(:permissions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:permissions, [permission | role.permissions])
    |> Repo.update()
  end

  @doc """
  Verifica si un usuario tiene un permiso específico.
  """
  def user_has_permission?(%User{} = user, permission_name) do
    query =
      from u in User,
        where: u.id == ^user.id,
        join: r in assoc(u, :roles),
        join: p in assoc(r, :permissions),
        where: p.name == ^permission_name,
        select: count(p.id)

    Repo.one(query) > 0
  end
end
