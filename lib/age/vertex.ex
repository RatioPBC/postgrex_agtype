defmodule Age.Vertex do
  @moduledoc """
  Struct representing a Vertex in an AGE graph, with underlying libgraph support.

  `alias`, `label`, and `properties` are kept in a map that is the single
  vertex label value of a vertex in the `graph`.
  """

  defstruct [:id, :graph]

  @type t :: %__MODULE__{
          id: Age.id(),
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
  Returns struct with updated graph containing this vertex and its attributes.
  """
  @spec new(Graph.t(), Age.id(), Age.label(), Age.properties(), Age.alias()) :: t()
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
  @spec from(Graph.t(), Age.id()) :: t()
  def from(graph, id) do
    unless Graph.has_vertex?(graph, id) do
      raise ArgumentError, "given graph does not contain vertex: #{id}"
    end

    %__MODULE__{id: id, graph: graph}
  end

  @doc """
  Returns the AGE vertex alias stored with this libgraph vertex.
  """
  @spec alias(t()) :: Age.alias()
  def alias(%__MODULE__{} = vertex), do: fetch_vertex_label_key!(vertex, "alias")

  @doc """
  Returns the AGE vertex label stored with this libgraph vertex.
  """
  @spec label(t()) :: Age.label()
  def label(%__MODULE__{} = vertex), do: fetch_vertex_label_key!(vertex, "label")

  @doc """
  Returns the AGE vertex properties(keys/values) stored with this libgraph
  vertex.
  """
  @spec properties(t()) :: Age.properties()
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
  @spec to_cypher(t(), Age.alias()) :: String.t()
  def to_cypher(%__MODULE__{} = vertex, alias \\ nil) do
    alias = alias || __MODULE__.alias(vertex)
    if is_nil(alias), do: raise(ArgumentError, "vertex alias value required")

    props =
      vertex
      |> properties()
      |> Age.map_to_cypher()

    "(" <> to_string(alias) <> ":" <> label(vertex) <> props <> ")"
  end
end
