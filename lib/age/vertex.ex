defmodule Age.Vertex do
  @moduledoc """
  Struct representing a Vertex in an AGE graph, with underlying libgraph support.

  `alias`, `label`, and `properties` are kept in a map that is the single
  vertex label value of a vertex in the `graph`.
  """

  defstruct [:id, :graph]

  @typedoc """
  `id` is the internal ID of an AGE vertex.
  """
  @type id :: pos_integer()

  @typedoc """
  `alias` is an optional atom or string of the alias of an AGE vertex, used for
  building cypher queries.
  """
  @type alias :: atom() | String.t() | nil

  @typedoc """
  `label` is a string of the label of an AGE vertex.
  """
  @type label :: String.t()

  @typedoc """
  `properties` is a map with the KV attributes of an AGE vertex.
  """
  @type properties :: %{optional(String.t()) => term()}

  @type t :: %__MODULE__{
          id: id(),
          graph: Graph.t()
        }

  defmodule VertexError do
    @moduledoc false

    defmacro __using__(opts) do
      message = Keyword.fetch!(opts, :message)

      quote do
        defexception [:message, :graph, :id]

        @impl true
        def exception(vertex) do
          message = "#{unquote(message)} - #{vertex.id} in #{inspect(vertex.graph)}"
          %__MODULE__{message: message}
        end
      end
    end
  end

  defmodule EmptyVertexLabelsError do
    @moduledoc """
    Empty label list found on a libgraph vertex.
    """

    use VertexError, message: "empty list encountered"
  end

  defmodule MultipleVertexLabelsError do
    @moduledoc """
    Multiple labels found on a libgraph vertex.
    """

    use VertexError, message: "list with length > 1 encountered"
  end

  @doc """
  """
  @spec new(Graph.t(), id(), label(), properties(), alias()) :: t()
  def new(graph, id, label, properties, alias \\ nil) do
    vertex_label = %{"alias" => alias, "label" => label, "properties" => properties}

    graph =
      if Graph.has_vertex?(graph, id) do
        graph
        |> Graph.remove_vertex_labels(id)
        |> Graph.label_vertex(id, vertex_label)
      else
        Graph.add_vertex(graph, id, vertex_label)
      end

    %__MODULE__{id: id, graph: graph}
  end

  @doc """
  Returns struct for given graph and vertex id, raising if the vertex is not
  part of the graph.
  """
  @spec from(Graph.t(), id()) :: t()
  def from(graph, id) do
    unless Graph.has_vertex?(graph, id) do
      raise ArgumentError, "given graph does not contain vertex: #{id}"
    end

    %__MODULE__{id: id, graph: graph}
  end

  @doc """
  Returns the AGE vertex alias stored with this libgraph vertex.
  """
  @spec alias(t()) :: alias()
  def alias(%__MODULE__{} = vertex) do
    vertex
    |> fetch_vertex_label!()
    |> Map.fetch!("alias")
  end

  @doc """
  Returns the AGE vertex label stored with this libgraph vertex.
  """
  @spec label(t()) :: label()
  def label(%__MODULE__{} = vertex), do: fetch_vertex_label_key!(vertex, "label")

  @doc """
  Returns the AGE vertex properties(keys/values) stored with this libgraph
  vertex.
  """
  @spec properties(t()) :: properties()
  def properties(%__MODULE__{} = vertex), do: fetch_vertex_label_key!(vertex, "properties")

  defp fetch_vertex_label_key!(vertex, key) do
    vertex
    |> fetch_vertex_label!()
    |> Map.fetch!(key)
  end

  defp fetch_vertex_label!(%__MODULE__{id: id, graph: graph} = vertex) do
    case Graph.vertex_labels(graph, id) do
      [] ->
        raise EmptyVertexLabelsError, vertex

      [label] ->
        label

      [_ | _] ->
        raise MultipleVertexLabelsError, vertex
    end
  end

  @doc """
  Generate cypher for this Vertex.
  """
  @spec to_cypher(t(), alias()) :: String.t()
  def to_cypher(%__MODULE__{} = vertex, alias \\ nil) do
    alias = alias || __MODULE__.alias(vertex)
    if is_nil(alias), do: raise(ArgumentError, "vertex alias value required")

    props =
      vertex
      |> properties()
      |> Enum.map_join(",", fn {k, v} -> "#{k}:#{Age.quote_string(v)}" end)
      |> then(fn
        "" = props ->
          props

        props ->
          " {" <> props <> "}"
      end)

    "(" <> to_string(alias) <> ":" <> label(vertex) <> props <> ")"
  end
end
