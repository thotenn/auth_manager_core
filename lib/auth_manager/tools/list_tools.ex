defmodule AuthManager.Tools.ListTools do
  @moduledoc """
  Utilidades para manipulación de listas.
  """

  @doc """
  Aplana una lista anidada en una única lista.

  ## Ejemplos

      iex> ListTools.flatten([1, [2, 3], [4, [5, 6]]])
      [1, 2, 3, 4, 5, 6]
  """
  def flatten(list) when is_list(list) do
    List.flatten(list)
  end

  @doc """
  Elimina duplicados de una lista, manteniendo el orden.

  ## Ejemplos

      iex> ListTools.unique([1, 2, 3, 2, 1, 4])
      [1, 2, 3, 4]
  """
  def unique(list) when is_list(list) do
    list |> Enum.uniq()
  end

  @doc """
  Agrupa los elementos de una lista por el resultado de una función.

  ## Ejemplos

      iex> ListTools.group_by([%{name: "Juan", age: 30}, %{name: "María", age: 30}, %{name: "Pedro", age: 25}], fn x -> x.age end)
      %{30 => [%{name: "Juan", age: 30}, %{name: "María", age: 30}], 25 => [%{name: "Pedro", age: 25}]}
  """
  def group_by(list, fun) when is_list(list) and is_function(fun, 1) do
    list |> Enum.group_by(fun)
  end

  @doc """
  Divide una lista en sublistas de un tamaño específico.

  ## Ejemplos

      iex> ListTools.chunk([1, 2, 3, 4, 5, 6, 7], 3)
      [[1, 2, 3], [4, 5, 6], [7]]
  """
  def chunk(list, size) when is_list(list) and is_integer(size) and size > 0 do
    list |> Enum.chunk_every(size)
  end

  @doc """
  Intercala un elemento entre cada elemento de una lista.

  ## Ejemplos

      iex> ListTools.intersperse([1, 2, 3], :sep)
      [1, :sep, 2, :sep, 3]
  """
  def intersperse(list, separator) when is_list(list) do
    list |> Enum.intersperse(separator)
  end

  @doc """
  Comprime elementos adyacentes duplicados en la lista.

  ## Ejemplos

      iex> ListTools.compress([1, 1, 2, 3, 3, 3, 4, 4, 1])
      [1, 2, 3, 4, 1]
  """
  def compress(list) when is_list(list) do
    list
    |> Enum.chunk_by(& &1)
    |> Enum.map(&List.first/1)
  end

  @doc """
  Rota una lista por un cierto número de posiciones.
  Si el número es positivo, rota a la izquierda.
  Si el número es negativo, rota a la derecha.

  ## Ejemplos

      iex> ListTools.rotate([1, 2, 3, 4, 5], 2)
      [3, 4, 5, 1, 2]

      iex> ListTools.rotate([1, 2, 3, 4, 5], -1)
      [5, 1, 2, 3, 4]
  """
  def rotate(list, n) when is_list(list) and is_integer(n) do
    len = length(list)

    if len == 0 do
      []
    else
      # Normalizar n para que esté en el rango [0, len-1]
      idx = rem(rem(n, len) + len, len)
      {left, right} = Enum.split(list, idx)
      right ++ left
    end
  end

  @doc """
  Agrupa elementos consecutivos en sublistas según el tamaño especificado.
  A diferencia de chunk, esto crea "ventanas deslizantes".

  ## Ejemplos

      iex> ListTools.sliding_window([1, 2, 3, 4, 5], 3)
      [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
  """
  def sliding_window(list, size) when is_list(list) and is_integer(size) and size > 0 do
    if length(list) < size do
      []
    else
      list
      |> Enum.chunk_every(size, 1, :discard)
    end
  end

  @doc """
  Encuentra todas las permutaciones de una lista.

  ## Ejemplos

      iex> ListTools.permutations([1, 2, 3])
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  """
  def permutations([]), do: [[]]
  def permutations(list) when is_list(list) do
    for h <- list, t <- permutations(list -- [h]), do: [h | t]
  end

  @doc """
  Encuentra todas las combinaciones de una lista, tomando n elementos.

  ## Ejemplos

      iex> ListTools.combinations([1, 2, 3], 2)
      [[1, 2], [1, 3], [2, 3]]
  """
  def combinations(_, 0), do: [[]]
  def combinations([], _), do: []
  def combinations([h | t], n) when is_list(t) and is_integer(n) and n > 0 do
    (for c <- combinations(t, n - 1), do: [h | c]) ++ combinations(t, n)
  end

  @doc """
  Intercala dos o más listas, alternando elementos.

  ## Ejemplos

      iex> ListTools.interleave([1, 2, 3], [4, 5, 6])
      [1, 4, 2, 5, 3, 6]

      iex> ListTools.interleave([1, 2], [3], [4, 5, 6])
      [1, 3, 4, 2, 5, 6]
  """
  def interleave(lists) when is_list(lists) do
    lists
    |> List.zip()
    |> Enum.flat_map(&Tuple.to_list/1)
    |> Enum.concat(
      lists
      |> Enum.map(&Enum.drop(&1, length(List.zip(lists))))
      |> Enum.concat()
    )
  end

  def interleave(list1, list2, list3 \\ [], list4 \\ []) do
    interleave([list1, list2, list3, list4] |> Enum.filter(&(&1 != [])))
  end
end
