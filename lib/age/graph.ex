defmodule Age.Graph do
  @moduledoc """
  Convenience wrapper for libgraph Graph in AGE context.
  """

  alias Age.{Edge, Vertex}

  defstruct edges: [], libgraph: Graph.new(), vertices: []

  @type t :: %__MODULE__{
          edges: [Edge.t()],
          libgraph: Graph.t(),
          vertices: [Vertex.t()]
        }

  @doc """
  Convenience function allowing pipelining of this struct through Age.Vertex.new/5
  """
  @spec add_vertex(t(), Vertex.t()) :: t()
  def add_vertex(%__MODULE__{libgraph: libgraph} = graph, vertex) do
    %__MODULE__{
      graph
      | libgraph: Graph.add_vertex(libgraph, vertex.id),
        vertices: [vertex | graph.vertices]
    }
  end

  @spec add_vertex(t(), Age.id(), Age.label(), Age.properties()) :: t()
  def add_vertex(%__MODULE__{} = graph, id, label, properties \\ %{}) do
    add_vertex(graph, %Vertex{id: id, label: label, properties: properties})
  end

  @doc """
  Convenience function allowing pipelining of this struct through Age.Edge.new/7
  """
  @spec add_edge(t(), Edge.t()) :: t()
  def add_edge(%__MODULE__{libgraph: libgraph} = graph, edge) do
    %__MODULE__{
      graph
      | libgraph: Graph.add_edge(libgraph, edge.v1, edge.v2, label: %{id: edge.id}),
        edges: [edge | graph.edges]
    }
  end

  @spec add_edge(t(), Age.id(), Age.id(), Age.id(), Age.label(), Age.properties()) ::
          t()
  def add_edge(%__MODULE__{} = graph, v1, v2, id, label, properties \\ %{}) do
    add_edge(graph, %Edge{
      v1: v1,
      v2: v2,
      id: id,
      label: label,
      properties: properties
    })
  end
end
