defmodule AuthManager.Tools.StringTools do
  @moduledoc """
  Utilidades para manipulación de strings.
  """

  @doc """
  Capitaliza la primera letra de cada palabra en un string.

  ## Ejemplos

      iex> StringTools.capitalize_words("hello world")
      "Hello World"

      iex> StringTools.capitalize_words("HELLO WORLD")
      "Hello World"

      iex> StringTools.capitalize_words("hello_world")
      "Hello_world"
  """
  def capitalize_words(string) when is_binary(string) do
    string
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Convierte un string a camelCase.

  ## Ejemplos

      iex> StringTools.to_camel_case("hello world")
      "helloWorld"

      iex> StringTools.to_camel_case("hello_world")
      "helloWorld"

      iex> StringTools.to_camel_case("HelloWorld")
      "helloWorld"
  """
  def to_camel_case(string) when is_binary(string) do
    string
    |> String.replace(~r/[\s_-]+(.)/u, fn _, c -> String.upcase(c) end)
    |> String.replace(~r/^(.)/u, fn _, c -> String.downcase(c) end)
  end

  @doc """
  Convierte un string a PascalCase.

  ## Ejemplos

      iex> StringTools.to_pascal_case("hello world")
      "HelloWorld"

      iex> StringTools.to_pascal_case("hello_world")
      "HelloWorld"

      iex> StringTools.to_pascal_case("helloWorld")
      "HelloWorld"
  """
  def to_pascal_case(string) when is_binary(string) do
    string
    |> to_camel_case()
    |> String.replace(~r/^(.)/u, fn _, c -> String.upcase(c) end)
  end

  @doc """
  Convierte un string a snake_case.

  ## Ejemplos

      iex> StringTools.to_snake_case("Hello World")
      "hello_world"

      iex> StringTools.to_snake_case("HelloWorld")
      "hello_world"

      iex> StringTools.to_snake_case("helloWorld")
      "hello_world"
  """
  def to_snake_case(string) when is_binary(string) do
    string
    |> String.replace(~r/\s+/u, "_")
    |> String.replace(~r/([a-z])([A-Z])/u, "\\1_\\2")
    |> String.downcase()
  end

  @doc """
  Convierte un string a kebab-case.

  ## Ejemplos

      iex> StringTools.to_kebab_case("Hello World")
      "hello-world"

      iex> StringTools.to_kebab_case("HelloWorld")
      "hello-world"

      iex> StringTools.to_kebab_case("hello_world")
      "hello-world"
  """
  def to_kebab_case(string) when is_binary(string) do
    string
    |> to_snake_case()
    |> String.replace("_", "-")
  end

  @doc """
  Trunca un string a una longitud máxima, añadiendo un sufijo si es necesario.

  ## Ejemplos

      iex> StringTools.truncate("Hello World", 5)
      "Hello..."

      iex> StringTools.truncate("Hello", 10)
      "Hello"

      iex> StringTools.truncate("Hello World", 8, ">>")
      "Hello W>>"
  """
  def truncate(string, max_length, suffix \\ "...") when is_binary(string) do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length - String.length(suffix)) <> suffix
    else
      string
    end
  end

  @doc """
  Genera un slug a partir de un string.

  ## Ejemplos

      iex> StringTools.slugify("Hello World")
      "hello-world"

      iex> StringTools.slugify("¡Hola, Mundo!")
      "hola-mundo"

      iex> StringTools.slugify("  Hello  World  ")
      "hello-world"
  """
  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/[\s-]+/u, "-")
    |> String.trim("-")
  end

  @doc """
  Convierte un string a bytecode (lista de bytes).

  ## Ejemplos

      iex> StringTools.to_bytecode("ABC")
      [65, 66, 67]
  """
  def to_bytecode(string) when is_binary(string) do
    string
    |> :binary.bin_to_list()
  end

  @doc """
  Convierte bytecode (lista de bytes) a string.

  ## Ejemplos

      iex> StringTools.from_bytecode([65, 66, 67])
      "ABC"
  """
  def from_bytecode(bytecode) when is_list(bytecode) do
    :binary.list_to_bin(bytecode)
  end

  @doc """
  Elimina caracteres no alfanuméricos de un string.

  ## Ejemplos

      iex> StringTools.alphanumeric_only("Hello, World! 123")
      "HelloWorld123"
  """
  def alphanumeric_only(string) when is_binary(string) do
    String.replace(string, ~r/[^a-zA-Z0-9]/u, "")
  end

  @doc """
  Formatea un string según un patrón con marcadores de posición.

  ## Ejemplos

      iex> StringTools.format_with_pattern("4111111111111111", "XXXX-XXXX-XXXX-XXXX")
      "4111-1111-1111-1111"

      iex> StringTools.format_with_pattern("123456789", "(XXX) XXX-XXX")
      "(123) 456-789"
  """
  def format_with_pattern(string, pattern) when is_binary(string) and is_binary(pattern) do
    chars = String.graphemes(string)

    pattern
    |> String.graphemes()
    |> Enum.reduce({[], chars}, fn
      "X", {result, [next | rest]} -> {[next | result], rest}
      char, {result, chars} -> {[char | result], chars}
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.join("")
  end
end
