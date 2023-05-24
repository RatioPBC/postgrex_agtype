defmodule Age do
  @moduledoc """
  AGE - A Graph Extension for PostgreSQL.
  """

  alias Age.{Edge, Vertex}

  @typedoc """
  `id` is the internal ID of an AGE edge or vertex.
  """
  @type id :: pos_integer()

  @typedoc """
  `alias` is an optional atom or string of the alias of an AGE edge or vertex,
  used for building cypher queries.
  """
  @type alias :: atom() | String.t() | nil

  @typedoc """
  `label` is a string of the label of an AGE edge or vertex.
  """
  @type label :: String.t()

  @typedoc """
  `properties` is a map with the KV attributes of an AGE edge or vertex.
  """
  @type properties :: %{optional(String.t()) => term()}

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
  Translate elixir map to Cypher KV.

  ## Examples

      iex> Age.map_to_cypher(%{:a => "b", "c" => 1, "d" => 1.1, "e" => false})
      " {a:'b',c:1,d:1.1,e:false}"

      iex> Age.map_to_cypher(%{})
      ""

  """
  @spec map_to_cypher(map()) :: String.t()
  def map_to_cypher(map) do
    map
    |> Enum.map_join(",", fn {k, v} -> "#{k}:#{quote_string(v)}" end)
    |> then(fn
      "" = props ->
        props

      props ->
        " {" <> props <> "}"
    end)
  end

  @doc """
  Translate Age.Edge to Cypher KV with vertices and directional arrows.
  """
  @spec edge_to_cypher(Edge.t(), alias(), alias(), alias()) :: String.t()
  def edge_to_cypher(edge, edge_alias \\ nil, v1_alias \\ nil, v2_alias \\ nil) do
    if is_nil(edge_alias || Edge.alias(edge)), do: raise(ArgumentError, "edge alias required")

    v1 = Vertex.from(edge.graph, edge.v1)
    if is_nil(v1_alias || Vertex.alias(v1)), do: raise(ArgumentError, "v1 alias required")

    v2 = Vertex.from(edge.graph, edge.v2)
    if is_nil(v2_alias || Vertex.alias(v2)), do: raise(ArgumentError, "v2 alias required")

    v1_cypher = Vertex.to_cypher(v1, v1_alias)
    edge_cypher = Edge.to_cypher(edge, edge_alias)
    v2_cypher = Vertex.to_cypher(v2, v2_alias)

    v1_cypher <> "-" <> edge_cypher <> "->" <> v2_cypher
  end
end
