defmodule Age do
  @moduledoc """
  AGE - A Graph Extension for PostgreSQL.
  """

  @typedoc """
  `id` is the internal ID of an AGE edge or vertex. Since this must exist
  for graph integrity, the convention is to use negative IDs for unpersisted
  entities. Positive IDs therefore indicate the entity has been persisted and
  returned from a cypher query.
  """
  @type id :: pos_integer() | nil

  @typedoc """
  `alias` is an optional atom or string of the alias of an AGE edge or vertex,
  used for building cypher queries.
  """
  @type alias :: atom() | String.t() | nil

  @typedoc """
  `label` is a string of the label of an AGE edge or vertex.
  """
  @type label :: String.t() | nil

  @typedoc """
  `property_value` is all the allowed types in AGE entities.
  """
  @type property_value :: integer() | float() | Decimal.t() | boolean() | String.t() | nil

  @typedoc """
  `properties` is a map with the KV attributes of an AGE edge or vertex.
  """
  @type properties :: %{
    optional(atom()) => property_value(),
    optional(String.t()) => property_value()
  }

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

  @doc """
  Translate label value to Cypher.

  ## Examples

      iex> Age.label_to_cypher(:Label)
      ":Label"

      iex> Age.label_to_cypher("Label")
      ":Label"

      iex> Age.label_to_cypher(nil)
      ""
  """
  @spec label_to_cypher(Age.label() | nil) :: String.t()
  def label_to_cypher(nil), do: ""

  def label_to_cypher(label), do: ":" <> to_string(label)

  @doc """
  Translate elixir map to Cypher KV.

  ## Examples

      iex> Age.map_to_cypher(%{:a => "b", "c" => 1, "d" => 1.1, "e" => false})
      " {a:'b',c:1,d:1.1,e:false}"

      iex> Age.map_to_cypher(%{:a => "b", "c" => 1, "d" => 1.1, "e" => false}, [:a, "c"])
      " {a:'b',c:1}"

      iex> Age.map_to_cypher(%{})
      ""

  """
  @spec map_to_cypher(map() | nil, list()) :: String.t()
  def map_to_cypher(map, keys \\ [])

  def map_to_cypher(map, _keys) when map == %{}, do: ""

  def map_to_cypher(map, keys) do
    map
    |> take_keys(keys)
    |> Enum.map_join(",", fn {k, v} -> "#{k}:#{quote_string(v)}" end)
    |> then(fn
      "" = props ->
        props

      props ->
        " {" <> props <> "}"
    end)
  end

  defp take_keys(map, []), do: map

  defp take_keys(map, keys), do: Map.take(map, keys)
end
