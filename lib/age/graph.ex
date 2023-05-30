defmodule Age.Graph do
  @moduledoc """
  Convenience wrapper for libgraph Graph in AGE context.
  """

  alias Age.{Edge, Vertex}

  defstruct graph: Graph.new()

  @type t :: %__MODULE__{
          graph: Graph.t()
        }

  @doc """
  Convenience function allowing pipelining of this struct through Age.Vertex.new/5
  """
  @spec add_vertex(t(), Age.id(), Age.label(), Age.properties(), Age.alias()) :: t()
  def add_vertex(%__MODULE__{graph: graph}, id, label, properties \\ %{}, alias \\ nil) do
    v = Vertex.new(graph, id, label, properties, alias)

    %__MODULE__{graph: v.graph}
  end

  @doc """
  Convenience function allowing pipelining of this struct through Age.Edge.new/7
  """
  @spec add_edge(t(), Age.id(), Age.id(), Age.id(), Age.label(), Age.properties(), Age.alias()) ::
          t()
  def add_edge(%__MODULE__{graph: graph}, v1, v2, id, label, properties \\ %{}, alias \\ nil) do
    e = Edge.new(graph, v1, v2, id, label, properties, alias)

    %__MODULE__{graph: e.graph}
  end
end
