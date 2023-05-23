defmodule Age.Node do
  @moduledoc """
  Struct representing a Node in an AGE graph, with underlying libgraph support.

  `alias`, `id`, `label`, and `properties` are kept in a map that is the single
  vertex label value of a vertex in the `graph`.
  """

  # defstruct [:id, :graph, :alias, :label, properties: %{}]
  defstruct [:id, :graph]

  @typedoc """
  `id` is the internal ID of an AGE node.
  """
  @type id :: pos_integer()

  @typedoc """
  `alias` is an optional atom or string of the alias of an AGE node, used for
  building cypher queries.
  """
  @type alias :: atom() | String.t() | nil

  @typedoc """
  `label` is a string of the label of an AGE node.
  """
  @type label :: String.t()

  @typedoc """
  `properties` is a map with the KV attributes of an AGE node.
  """
  @type properties :: %{optional(String.t()) => term()}

  @type t :: %__MODULE__{
          id: id(),
          graph: Graph.t()
          # graph: Graph.t(),
          # alias: alias(),
          # label: label(),
          # properties: properties()
        }

  defmodule NodeError do
    @moduledoc false

    defmacro __using__(opts) do
      message = Keyword.fetch!(opts, :message)

      quote do
        defexception [:message, :graph, :id]

        @impl true
        def exception(node) do
          message = "#{unquote(message)} - #{node.id} in #{inspect(node.graph)}"
          %__MODULE__{message: message}
        end
      end
    end
  end

  defmodule EmptyVertexLabelsError do
    @moduledoc """
    Empty label list found on a libgraph vertex.
    """

    use NodeError, message: "empty list encountered"
  end

  defmodule MultipleVertexLabelsError do
    @moduledoc """
    Multiple labels found on a libgraph vertex.
    """

    use NodeError, message: "list with length > 1 encountered"
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

    # %__MODULE__{id: id, graph: graph, alias: alias, label: label, properties: properties}
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

    # %{"alias" => alias, "label" => label, "properties" => properties} =
    #   fetch_vertex_label!(%__MODULE__{id: id, graph: graph})

    # %__MODULE__{id: id, graph: graph, alias: alias, label: label, properties: properties}
    %__MODULE__{id: id, graph: graph}
  end

  @doc """
  Returns the AGE node alias stored with this vertex.
  """
  @spec alias(t()) :: alias()
  def alias(%__MODULE__{} = node) do
    node
    |> fetch_vertex_label!()
    |> Map.fetch!("alias")
  end

  @doc """
  Returns the AGE node label stored with this vertex.
  """
  @spec label(t()) :: label()
  def label(%__MODULE__{} = node), do: fetch_vertex_label_key!(node, "label")

  @doc """
  Returns the AGE node properties(keys/values) stored with this vertex.
  """
  @spec properties(t()) :: properties()
  def properties(%__MODULE__{} = node), do: fetch_vertex_label_key!(node, "properties")

  defp fetch_vertex_label_key!(node, key) do
    node
    |> fetch_vertex_label!()
    |> Map.fetch!(key)
  end

  defp fetch_vertex_label!(%__MODULE__{id: id, graph: graph} = node) do
    case Graph.vertex_labels(graph, id) do
      [] ->
        raise EmptyVertexLabelsError, node

      [label] ->
        label

      [_ | _] ->
        raise MultipleVertexLabelsError, node
    end
  end

  @doc """
  Generate cypher for this Node.
  """
  @spec to_cypher(t(), alias()) :: String.t()
  def to_cypher(%__MODULE__{} = node, alias \\ nil) do
    alias = alias || __MODULE__.alias(node)
    if is_nil(alias), do: raise(ArgumentError, "node alias value required")

    props =
      node
      |> properties()
      |> Enum.map_join(",", fn {k, v} -> "#{k}:#{Age.quote_string(v)}" end)
      |> then(fn
        "" = props ->
          props

        props ->
          " {" <> props <> "}"
      end)

    "(" <> to_string(alias) <> ":" <> label(node) <> props <> ")"
  end
end
