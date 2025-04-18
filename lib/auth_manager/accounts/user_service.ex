defmodule AuthManager.Accounts.UserService do
  @moduledoc """
  Servicio para operaciones relacionadas con usuarios.
  """
  import Ecto.Query
  alias AuthManager.Accounts.User
  alias AuthManager.Core.Config

  @doc """
  Autentica a un usuario por nombre de usuario/email y contraseña.

  ## Ejemplos

      iex> UserService.authenticate("usuario", "contraseña")
      {:ok, %User{}}

      iex> UserService.authenticate("usuario", "incorrecta")
      {:error, :invalid_credentials}
  """
  def authenticate(username_or_email, password) do
    repo = Config.repo()

    user = from(u in User,
              where: u.username == ^username_or_email or u.email == ^username_or_email,
              where: u.is_active == true,
              limit: 1)
           |> repo.one()

    case user do
      nil ->
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          # Actualizar último inicio de sesión
          {:ok, user} = user
                        |> User.login_changeset()
                        |> repo.update()

          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Cambia la contraseña de un usuario.

  ## Ejemplos

      iex> UserService.change_password(user, "nueva_contraseña")
      {:ok, %User{}}
  """
  def change_password(user, password) do
    repo = Config.repo()

    user
    |> User.password_changeset(%{password: password})
    |> repo.update()
  end

  @doc """
  Inactiva un usuario.

  ## Ejemplos

      iex> UserService.inactivate(user)
      {:ok, %User{}}
  """
  def inactivate(user) do
    repo = Config.repo()

    user
    |> Ecto.Changeset.change(%{is_active: false})
    |> repo.update()
  end

  @doc """
  Activa un usuario.

  ## Ejemplos

      iex> UserService.activate(user)
      {:ok, %User{}}
  """
  def activate(user) do
    repo = Config.repo()

    user
    |> Ecto.Changeset.change(%{is_active: true})
    |> repo.update()
  end

  @doc """
  Actualiza los datos de un usuario.

  ## Ejemplos

      iex> UserService.update_user(user, %{first_name: "Nuevo Nombre"})
      {:ok, %User{}}
  """
  def update_user(user, attrs) do
    repo = Config.repo()

    user
    |> User.update_changeset(attrs)
    |> repo.update()
  end

  @doc """
  Busca usuarios según criterios.

  ## Ejemplos

      iex> UserService.search_users(search: "juan", active: true)
      [%User{}, ...]
  """
  def search_users(opts \\ []) do
    repo = Config.repo()

    search_term = Keyword.get(opts, :search)
    active = Keyword.get(opts, :active)
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    User
    |> search_by_term(search_term)
    |> filter_by_active(active)
    |> limit(^limit)
    |> offset(^offset)
    |> repo.all()
  end

  @doc """
  Cuenta el número de usuarios según criterios de búsqueda.

  ## Ejemplos

      iex> UserService.count_users(search: "juan", active: true)
      5
  """
  def count_users(opts \\ []) do
    repo = Config.repo()

    search_term = Keyword.get(opts, :search)
    active = Keyword.get(opts, :active)

    User
    |> search_by_term(search_term)
    |> filter_by_active(active)
    |> select([u], count(u.id))
    |> repo.one()
  end

  @doc """
  Obtiene un usuario por su ID.

  ## Ejemplos

      iex> UserService.get_user(1)
      %User{}

      iex> UserService.get_user(999)
      nil
  """
  def get_user(id) do
    repo = Config.repo()
    repo.get(User, id)
  end

  @doc """
  Obtiene un usuario por su ID, lanzando un error si no existe.

  ## Ejemplos

      iex> UserService.get_user!(1)
      %User{}

      iex> UserService.get_user!(999)
      ** (Ecto.NoResultsError)
  """
  def get_user!(id) do
    repo = Config.repo()
    repo.get!(User, id)
  end

  @doc """
  Obtiene un usuario por su nombre de usuario.

  ## Ejemplos

      iex> UserService.get_by_username("juanperez")
      %User{}
  """
  def get_by_username(username) do
    repo = Config.repo()
    repo.get_by(User, username: username)
  end

  @doc """
  Obtiene un usuario por su email.

  ## Ejemplos

      iex> UserService.get_by_email("juan@example.com")
      %User{}
  """
  def get_by_email(email) do
    repo = Config.repo()
    repo.get_by(User, email: email)
  end

  # Helpers privados para las consultas

  defp search_by_term(query, nil), do: query
  defp search_by_term(query, search_term) do
    search_pattern = "%#{search_term}%"

    from u in query,
      where: ilike(u.username, ^search_pattern) or
             ilike(u.email, ^search_pattern) or
             ilike(u.first_name, ^search_pattern) or
             ilike(u.last_name, ^search_pattern)
  end

  defp filter_by_active(query, nil), do: query
  defp filter_by_active(query, active) do
    from u in query, where: u.is_active == ^active
  end
end
