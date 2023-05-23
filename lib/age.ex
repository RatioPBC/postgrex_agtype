defmodule Age do
  @moduledoc """
  AGE
  """

  @doc """
  Surround properties with curly brackets and leading space, if needed.

  ## Examples

      iex> Age.wrap_properties("foo:'bar',baz:123.45,bat:true")
      " {foo:'bar',baz:123.45,bat:true}"

      iex> Age.wrap_properties("")
      ""

  """
  @spec wrap_properties(String.t()) :: String.t()
  def wrap_properties("" = p), do: p

  def wrap_properties(p) when is_binary(p), do: " {" <> p <> "}"

  def wrap_properties(p), do: raise(ArgumentError, "unsupported value type: #{inspect(p)}")

  @doc """
  Surround a string value with single quotes if not already, or return
  non-string value unchanged.

  ## Examples

      iex> Age.quote_string("foo")
      "'foo'"

      iex> Age.quote_string("'foo")
      "'foo'"

      iex> Age.quote_string("foo'")
      "'foo'"

      iex> Age.quote_string(123)
      123

      iex> Age.quote_string(123.45)
      123.45

      iex> Age.quote_string(true)
      true

  """
  @spec quote_string(any()) :: any()
  def quote_string(v) when is_binary(v), do: quote_if_not(v, 0) <> v <> quote_if_not(v, -1)

  def quote_string(v) when is_integer(v), do: v

  def quote_string(v) when is_float(v), do: v

  def quote_string(v) when is_boolean(v), do: v

  def quote_string(v), do: raise(ArgumentError, "unsupported value type: #{inspect(v)}")

  defp quote_if_not(v, pos),
    do: if(String.at(v, pos) != "'", do: "'", else: "")
end
