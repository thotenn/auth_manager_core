defmodule AuthManager.Core.Controller do
  @moduledoc """
  Controlador principal que proporciona funciones para gestionar usuarios, roles y permisos.
  """
  import Ecto.Query
  alias AuthManager.Accounts.User
  alias AuthManager.Authorization.{
    Permission,
    Role,
    UserRole,
    UserPermission,
    RolePermission,
    RoleRole
  }

  @doc """
  Obtiene el repositorio configurado para la aplicación.
  """
  def repo do
    Application.get_env(:auth_manager, :repo) ||
      raise "Por favor, configura :auth_manager, :repo en tus archivos de configuración"
  end

  #
  # Funciones de creación
  #

  @doc """
  Crea un nuevo usuario.
  """
  def create_user(attrs) do
    %User{}
    |> User.create_changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Crea un nuevo rol.
  """
  def create_role(attrs) do
    %Role{}
    |> Role.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Crea un nuevo permiso.
  """
  def create_permission(attrs) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> repo().insert()
  end

  #
  # Funciones de asignación
  #

  @doc """
  Asigna un rol a un usuario.
  """
  def assign_role_to_user(user, role, opts \\ []) do
    user_id = get_id(user)
    role_id = get_id(role)

    attrs = %{
      user_id: user_id,
      role_id: role_id,
      assigned_by: Keyword.get(opts, :assigned_by),
      notes: Keyword.get(opts, :notes)
    }

    %UserRole{}
    |> UserRole.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Asigna un permiso a un usuario.
  """
  def assign_permission_to_user(user, permission, opts \\ []) do
    user_id = get_id(user)
    permission_id = get_id(permission)

    attrs = %{
      user_id: user_id,
      permission_id: permission_id,
      assigned_by: Keyword.get(opts, :assigned_by),
      notes: Keyword.get(opts, :notes)
    }

    %UserPermission{}
    |> UserPermission.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Asigna un permiso a un rol.
  """
  def assign_permission_to_role(role, permission, opts \\ []) do
    role_id = get_id(role)
    permission_id = get_id(permission)

    attrs = %{
      role_id: role_id,
      permission_id: permission_id,
      assigned_by: Keyword.get(opts, :assigned_by),
      notes: Keyword.get(opts, :notes)
    }

    %RolePermission{}
    |> RolePermission.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Asigna un rol padre a un rol hijo.
  """
  def assign_parent_role(child_role, parent_role, opts \\ []) do
    child_role_id = get_id(child_role)
    parent_role_id = get_id(parent_role)

    attrs = %{
      child_role_id: child_role_id,
      parent_role_id: parent_role_id,
      assigned_by: Keyword.get(opts, :assigned_by),
      notes: Keyword.get(opts, :notes)
    }

    %RoleRole{}
    |> RoleRole.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Asigna un permiso padre a un permiso hijo.
  """
  def assign_parent_permission(child_permission, parent_permission) do
    child_id = get_id(child_permission)
    parent_id = get_id(parent_permission)

    child_permission = repo().get!(Permission, child_id)

    child_permission
    |> Ecto.Changeset.change(%{parent_id: parent_id})
    |> repo().update()
  end

  #
  # Funciones de verificación
  #

  @doc """
  Verifica si un usuario tiene un permiso específico.
  Considera permisos directos, heredados a través de roles y padres de permisos.
  """
  def can?(user, permission) do
    user_id = get_id(user)
    permission = get_permission(permission)

    # 1. Verificar si el usuario tiene el permiso directamente asignado
    direct_permission = from(up in UserPermission,
                          where: up.user_id == ^user_id and up.permission_id == ^permission.id,
                          limit: 1)
                        |> repo().exists?()

    if direct_permission do
      true
    else
      # 2. Verificar a través de los roles del usuario
      user_roles = get_user_roles(user)

      has_permission_through_role = Enum.any?(user_roles, fn role ->
        role_has_permission?(role, permission)
      end)

      if has_permission_through_role do
        true
      else
        # 3. Verificar a través de permisos padre
        parent_permissions = Permission.get_all_parents(repo(), permission.id)

        Enum.any?(parent_permissions, fn parent ->
          can?(user, parent)
        end)
      end
    end
  end

  @doc """
  Verifica si un usuario tiene un rol específico.
  Considera roles directos y heredados a través de roles padres.
  """
  def has_role?(user, role) do
    user_id = get_id(user)
    role = get_role(role)

    # 1. Verificar si el usuario tiene el rol directamente asignado
    direct_role = from(ur in UserRole,
                     where: ur.user_id == ^user_id and ur.role_id == ^role.id,
                     limit: 1)
                  |> repo().exists?()

    if direct_role do
      true
    else
      # 2. Verificar a través de los roles padre de los roles del usuario
      user_roles = get_user_roles(user)

      Enum.any?(user_roles, fn user_role ->
        # Obtener todos los roles padre del rol asignado al usuario
        parent_roles = Role.get_all_parent_roles(repo(), user_role.id)

        # Verificar si el rol requerido está entre los roles padre
        Enum.any?(parent_roles, fn parent_role ->
          parent_role.id == role.id
        end)
      end)
    end
  end

  @doc """
  Verifica si un rol tiene un permiso específico.
  Considera permisos directos y heredados a través de roles padres.
  """
  def role_has_permission?(role, permission) do
    role = get_role(role)
    permission = get_permission(permission)

    # 1. Verificar si el rol tiene el permiso directamente asignado
    direct_permission = from(rp in RolePermission,
                           where: rp.role_id == ^role.id and rp.permission_id == ^permission.id,
                           limit: 1)
                        |> repo().exists?()

    if direct_permission do
      true
    else
      # 2. Verificar a través de los roles padre
      parent_roles = Role.get_all_parent_roles(repo(), role.id)

      Enum.any?(parent_roles, fn parent_role ->
        from(rp in RolePermission,
           where: rp.role_id == ^parent_role.id and rp.permission_id == ^permission.id,
           limit: 1)
        |> repo().exists?()
      end)
    end
  end

  @doc """
  Función unificada para verificar permisos o roles.

  Opciones admitidas:
  - user: El usuario a verificar
  - permission: El permiso a verificar
  - role: El rol a verificar

  Ejemplos:
  ```
  can_by?(user: user, permission: "delete_users")
  can_by?(user: user, role: "admin")
  can_by?(role: "editor", permission: "edit_articles")
  ```
  """
  def can_by?(opts) do
    user = Keyword.get(opts, :user)
    permission = Keyword.get(opts, :permission)
    role = Keyword.get(opts, :role)

    cond do
      user && permission ->
        can?(user, permission)

      user && role ->
        has_role?(user, role)

      role && permission ->
        role = get_role(role)
        permission = get_permission(permission)
        role_has_permission?(role, permission)

      true ->
        raise ArgumentError, "Combinación de parámetros inválida para can_by?/1"
    end
  end

  #
  # Funciones de consulta
  #

  @doc """
  Obtiene todos los permisos de un usuario.
  Incluye permisos directos y a través de roles.
  """
  def get_user_permissions(user) do
    user_id = get_id(user)

    # 1. Obtener permisos directamente asignados
    direct_permissions_query = from(up in UserPermission,
                                  where: up.user_id == ^user_id,
                                  join: p in assoc(up, :permission),
                                  select: p)

    direct_permissions = repo().all(direct_permissions_query)

    # 2. Obtener permisos a través de roles
    role_permissions = get_user_roles(user)
                       |> Enum.flat_map(fn role ->
                         get_role_permissions(role)
                       end)

    # 3. Combinar y eliminar duplicados
    (direct_permissions ++ role_permissions)
    |> Enum.uniq_by(fn p -> p.id end)
  end

  @doc """
  Obtiene todos los roles de un usuario.
  """
  def get_user_roles(user) do
    user_id = get_id(user)

    query = from(ur in UserRole,
               where: ur.user_id == ^user_id,
               join: r in assoc(ur, :role),
               select: r)

    repo().all(query)
  end

  @doc """
  Obtiene todos los permisos de un rol.
  Incluye permisos directos y a través de roles padre.
  """
  def get_role_permissions(role) do
    role_id = get_id(role)

    # 1. Obtener permisos directamente asignados
    direct_permissions_query = from(rp in RolePermission,
                                  where: rp.role_id == ^role_id,
                                  join: p in assoc(rp, :permission),
                                  select: p)

    direct_permissions = repo().all(direct_permissions_query)

    # 2. Obtener permisos a través de roles padre
    parent_roles = Role.get_all_parent_roles(repo(), role_id)

    parent_permissions = Enum.flat_map(parent_roles, fn parent_role ->
      from(rp in RolePermission,
         where: rp.role_id == ^parent_role.id,
         join: p in assoc(rp, :permission),
         select: p)
      |> repo().all()
    end)

    # 3. Combinar y eliminar duplicados
    (direct_permissions ++ parent_permissions)
    |> Enum.uniq_by(fn p -> p.id end)
  end

  @doc """
  Obtiene todos los usuarios.
  """
  def get_all_users do
    repo().all(User)
  end

  @doc """
  Obtiene todos los roles.
  """
  def get_all_roles do
    repo().all(Role)
  end

  @doc """
  Obtiene todos los permisos.
  """
  def get_all_permissions do
    repo().all(Permission)
  end

  #
  # Funciones auxiliares
  #

  # Obtiene el ID de un objeto o lo devuelve si ya es un ID
  defp get_id(nil), do: nil
  defp get_id(%{id: id}), do: id
  defp get_id(id) when is_integer(id) or is_binary(id), do: id

  # Obtiene un permiso por su ID, slug o nombre, o lo devuelve si ya es un permiso
  defp get_permission(%Permission{} = permission), do: permission
  defp get_permission(identifier) when is_integer(identifier) do
    repo().get!(Permission, identifier)
  end
  defp get_permission(identifier) when is_binary(identifier) do
    # Primero intenta buscar por slug
    permission = repo().get_by(Permission, slug: identifier)

    # Si no encuentra, intenta buscar por nombre
    permission || repo().get_by!(Permission, name: identifier)
  end

  # Obtiene un rol por su ID, slug o nombre, o lo devuelve si ya es un rol
  defp get_role(%Role{} = role), do: role
  defp get_role(identifier) when is_integer(identifier) do
    repo().get!(Role, identifier)
  end
  defp get_role(identifier) when is_binary(identifier) do
    # Primero intenta buscar por slug
    role = repo().get_by(Role, slug: identifier)

    # Si no encuentra, intenta buscar por nombre
    role || repo().get_by!(Role, name: identifier)
  end
end
