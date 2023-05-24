defmodule Age.Edge do
  @moduledoc """
  Struct representing an Edge in an AGE graph, with underlying libgraph support.

  `alias`, `id`, `label`, and `properties` are kept in a map that is the single
  vertex label value of a vertex in the `graph`.
  """

  defstruct [:graph, :id, :v1, :v2]

  @type weight :: integer() | float()

  @type t :: %__MODULE__{
          graph: Graph.t(),
          id: Age.id(),
          v1: Age.id(),
          v2: Age.id()
        }

  @doc """
  Returns struct with updated graph containing this edge, vertices, and attributes.
  """
  @spec new(Graph.t(), Age.id(), Age.id(), Age.id(), Age.label(), Age.properties(), Age.alias()) ::
          t()
  def new(graph, v1, v2, id, label, properties, alias \\ nil) do
    weight = Map.get(properties, "weight", 1)

    edge_label = %{
      "alias" => alias,
      "id" => id,
      "label" => label,
      "properties" => Map.drop(properties, ["weight"])
    }

    edge = find_edge_with_id(graph, v1, v2, id)

    graph =
      if edge do
        Graph.update_labelled_edge(graph, v1, v2, edge.label, label: edge_label, weight: weight)
      else
        Graph.add_edge(graph, v1, v2, label: edge_label, weight: weight)
      end

    %__MODULE__{graph: graph, id: id, v1: v1, v2: v2}
  end

  @doc """
  Returns struct for given graph and edge id, raising if the edge is not part
  of the graph.
  """
  @spec from(Graph.t(), Age.id(), Age.id(), Age.id()) :: t()
  def from(graph, v1, v2, id) do
    if _edge = find_edge_with_id(graph, v1, v2, id) do
      %__MODULE__{graph: graph, id: id, v1: v1, v2: v2}
    else
      raise ArgumentError, "edge with id '#{id}' not found in graph"
    end
  end

  defp find_edge_with_id(graph, v1, v2, id) do
    graph
    |> Graph.edges(v1, v2)
    |> Enum.find(fn
      %Graph.Edge{label: %{"id" => ^id}} -> true
      _ -> false
    end)
  end

  @doc """
  Returns the AGE edge alias stored with this libgraph edge.
  """
  @spec alias(t()) :: Age.alias()
  def alias(%__MODULE__{} = edge), do: fetch_edge_label_key!(edge, "alias")

  @doc """
  Returns the AGE edge label stored with this libgraph edge.
  """
  @spec label(t()) :: Age.label()
  def label(%__MODULE__{} = edge), do: fetch_edge_label_key!(edge, "label")

  @doc """
  Returns the AGE edge properties(keys/values) stored with this libgraph edge.
  """
  @spec properties(t()) :: Age.properties()
  def properties(%__MODULE__{} = edge), do: fetch_edge_label_key!(edge, "properties")

  defp fetch_edge_label_key!(edge, key) do
    edge
    |> fetch_edge_label!()
    |> Map.fetch!(key)
  end

  defp fetch_edge_label!(%__MODULE__{} = edge) do
    %Graph.Edge{label: label, weight: weight} =
      find_edge_with_id(edge.graph, edge.v1, edge.v2, edge.id)

    put_in(label, ["properties", "weight"], weight)
  end

  @doc """
  Generate cypher for this Edge.
  """
  @spec to_cypher(t(), Age.alias()) :: String.t()
  def to_cypher(%__MODULE__{} = edge, alias \\ nil) do
    alias = alias || __MODULE__.alias(edge)
    if is_nil(alias), do: raise(ArgumentError, "edge alias value required")

    props =
      edge
      |> properties()
      |> Age.map_to_cypher()

    "[" <> to_string(alias) <> ":" <> label(edge) <> props <> "]"
  end
end
