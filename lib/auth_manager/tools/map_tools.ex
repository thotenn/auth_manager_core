defmodule AuthManager.Tools.MapTools do
  @moduledoc """
  Utilidades para manipulación de mapas.
  """

  @doc """
  Convierte claves de string a átomos en un mapa, recursivamente.

  ## Ejemplos

      iex> MapTools.keys_to_atoms(%{"name" => "Juan", "age" => 30})
      %{name: "Juan", age: 30}

      iex> MapTools.keys_to_atoms(%{"user" => %{"name" => "Juan", "age" => 30}})
      %{user: %{name: "Juan", age: 30}}
  """
  def keys_to_atoms(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      {
        (if is_binary(k), do: String.to_atom(k), else: k),
        (if is_map(v), do: keys_to_atoms(v), else: v)
      }
    end)
    |> Enum.into(%{})
  end

  @doc """
  Convierte claves de átomos a strings en un mapa, recursivamente.

  ## Ejemplos

      iex> MapTools.keys_to_strings(%{name: "Juan", age: 30})
      %{"name" => "Juan", "age" => 30}

      iex> MapTools.keys_to_strings(%{user: %{name: "Juan", age: 30}})
      %{"user" => %{"name" => "Juan", "age" => 30}}
  """
  def keys_to_strings(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      {
        (if is_atom(k), do: Atom.to_string(k), else: k),
        (if is_map(v), do: keys_to_strings(v), else: v)
      }
    end)
    |> Enum.into(%{})
  end

  @doc """
  Aplana un mapa anidado en un mapa plano con claves compuestas.

  ## Ejemplos

      iex> MapTools.flatten(%{user: %{name: "Juan", address: %{city: "Madrid"}}})
      %{"user.name" => "Juan", "user.address.city" => "Madrid"}
  """
  def flatten(map, prefix \\ "") do
    map
    |> Enum.flat_map(fn {key, val} ->
      key_name = prefix <> to_string(key)

      if is_map(val) and not Map.has_key?(val, :__struct__) do
        flatten(val, key_name <> ".")
      else
        [{key_name, val}]
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Desaplana un mapa plano con claves compuestas en un mapa anidado.

  ## Ejemplos

      iex> MapTools.unflatten(%{"user.name" => "Juan", "user.address.city" => "Madrid"})
      %{"user" => %{"name" => "Juan", "address" => %{"city" => "Madrid"}}}
  """
  def unflatten(map) do
    map
    |> Enum.reduce(%{}, fn {key, val}, acc ->
      parts = String.split(key, ".")
      put_in_parts(acc, parts, val)
    end)
  end

  defp put_in_parts(map, [key], value) do
    Map.put(map, key, value)
  end

  defp put_in_parts(map, [key | rest], value) do
    current = Map.get(map, key, %{})
    Map.put(map, key, put_in_parts(current, rest, value))
  end

  @doc """
  Fusiona dos mapas profundamente, combinando mapas anidados.

  ## Ejemplos

      iex> MapTools.deep_merge(%{a: 1, b: %{c: 2}}, %{b: %{d: 3}, e: 4})
      %{a: 1, b: %{c: 2, d: 3}, e: 4}
  """
  def deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, left_val, right_val ->
      if is_map(left_val) and is_map(right_val) do
        deep_merge(left_val, right_val)
      else
        right_val
      end
    end)
  end

  @doc """
  Filtra un mapa recursivamente, manteniendo solo las entradas que cumplen
  con la función de predicado.

  ## Ejemplos

      iex> MapTools.deep_filter(%{a: 1, b: %{c: 2, d: nil}}, fn {_k, v} -> not is_nil(v) end)
      %{a: 1, b: %{c: 2}}
  """
  def deep_filter(map, predicate) when is_map(map) and is_function(predicate, 1) do
    map
    |> Enum.filter(predicate)
    |> Enum.map(fn {k, v} ->
      if is_map(v) do
        {k, deep_filter(v, predicate)}
      else
        {k, v}
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Transforma los valores de un mapa recursivamente utilizando una función.

  ## Ejemplos

      iex> MapTools.deep_map(%{a: 1, b: %{c: 2}}, fn v -> v * 2 end)
      %{a: 2, b: %{c: 4}}
  """
  def deep_map(map, fun) when is_map(map) and is_function(fun, 1) do
    map
    |> Enum.map(fn {k, v} ->
      if is_map(v) and not Map.has_key?(v, :__struct__) do
        {k, deep_map(v, fun)}
      else
        {k, fun.(v)}
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Obtiene un valor de un mapa anidado utilizando una lista de claves o una ruta separada por puntos.

  ## Ejemplos

      iex> MapTools.get_in_path(%{user: %{name: "Juan"}}, [:user, :name])
      "Juan"

      iex> MapTools.get_in_path(%{user: %{name: "Juan"}}, "user.name")
      "Juan"
  """
  def get_in_path(map, path) when is_map(map) and is_binary(path) do
    keys = path
           |> String.split(".")
           |> Enum.map(fn key ->
             try do
               String.to_existing_atom(key)
             rescue
               _ -> key
             end
           end)

    get_in_path(map, keys)
  end

  def get_in_path(map, path) when is_map(map) and is_list(path) do
    get_in(map, path)
  end
end
