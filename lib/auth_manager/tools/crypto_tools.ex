defmodule AuthManager.Tools.CryptoTools do
  @moduledoc """
  Utilidades para operaciones criptográficas.
  """

  @doc """
  Genera un hash seguro de una contraseña utilizando bcrypt.

  ## Ejemplos

      iex> CryptoTools.hash_password("secretpassword")
      "$2b$12$..."
  """
  def hash_password(password) when is_binary(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  @doc """
  Verifica si una contraseña coincide con un hash.

  ## Ejemplos

      iex> CryptoTools.verify_password("secretpassword", "$2b$12$...")
      true
  """
  def verify_password(password, hash) when is_binary(password) and is_binary(hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @doc """
  Genera un token aleatorio de una longitud específica.

  ## Ejemplos

      iex> CryptoTools.generate_token(16)
      "f3d8e1c5a9b7..."
  """
  def generate_token(length \\ 32) when is_integer(length) and length > 0 do
    :crypto.strong_rand_bytes(length)
    |> Base.encode16(case: :lower)
    |> binary_part(0, length)
  end

  @doc """
  Cifra un string utilizando AES en modo GCM.

  ## Ejemplos

      iex> key = :crypto.strong_rand_bytes(32)
      iex> {encrypted, iv, tag} = CryptoTools.encrypt("datos secretos", key)
  """
  def encrypt(plaintext, key, aad \\ "") when is_binary(plaintext) and is_binary(key) do
    iv = :crypto.strong_rand_bytes(16)

    {ciphertext, tag} = :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      plaintext,
      aad,
      true
    )

    {ciphertext, iv, tag}
  end

  @doc """
  Descifra datos cifrados con AES en modo GCM.

  ## Ejemplos

      iex> CryptoTools.decrypt(encrypted, iv, tag, key)
      "datos secretos"
  """
  def decrypt(ciphertext, iv, tag, key, aad \\ "") do
    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      ciphertext,
      aad,
      tag,
      false
    )
  end

  @doc """
  Cifra un string y lo codifica en base64 para almacenamiento o transmisión.

  ## Ejemplos

      iex> key = :crypto.strong_rand_bytes(32)
      iex> encrypted = CryptoTools.encrypt_and_encode("datos secretos", key)
  """
  def encrypt_and_encode(plaintext, key, aad \\ "") do
    {ciphertext, iv, tag} = encrypt(plaintext, key, aad)

    # Concatenar IV, ciphertext y tag, y codificar en base64
    iv <> ciphertext <> tag
    |> Base.encode64()
  end

  @doc """
  Decodifica y descifra datos que fueron cifrados y codificados con encrypt_and_encode/3.

  ## Ejemplos

      iex> CryptoTools.decode_and_decrypt(encrypted, key)
      "datos secretos"
  """
  def decode_and_decrypt(encoded_str, key, aad \\ "") do
    decoded = Base.decode64!(encoded_str)

    # Extraer IV (16 bytes), tag (16 bytes) y ciphertext
    <<iv::binary-size(16), rest::binary>> = decoded
    ciphertext_size = byte_size(rest) - 16
    <<ciphertext::binary-size(ciphertext_size), tag::binary>> = rest

    decrypt(ciphertext, iv, tag, key, aad)
  end

  @doc """
  Genera un hash HMAC utilizando SHA-256.

  ## Ejemplos

      iex> CryptoTools.hmac("datos", "secreto")
      "..."
  """
  def hmac(data, key) when is_binary(data) and is_binary(key) do
    :crypto.mac(:hmac, :sha256, key, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Genera un hash SHA-256 de los datos proporcionados.

  ## Ejemplos

      iex> CryptoTools.sha256("hello world")
      "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
  """
  def sha256(data) when is_binary(data) do
    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Genera un hash MD5 de los datos proporcionados.
  Nota: MD5 no debe usarse para seguridad, solo para checksums o identificadores no sensibles.

  ## Ejemplos

      iex> CryptoTools.md5("hello world")
      "5eb63bbbe01eeed093cb22bb8f5acdc3"
  """
  def md5(data) when is_binary(data) do
    :crypto.hash(:md5, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Deriva una clave a partir de una contraseña utilizando PBKDF2.

  ## Ejemplos

      iex> salt = :crypto.strong_rand_bytes(16)
      iex> CryptoTools.derive_key("mypassword", salt, 10000, 32)
      <<...>>
  """
  def derive_key(password, salt, iterations \\ 10000, key_length \\ 32) do
    :crypto.pbkdf2_hmac(
      :sha256,
      password,
      salt,
      iterations,
      key_length
    )
  end
end
