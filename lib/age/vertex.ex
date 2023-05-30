defmodule Age.Vertex do
  @moduledoc """
  Struct representing a Vertex in an AGE graph.
  """

  defstruct [:id, :label, properties: %{}]

  @type t :: %__MODULE__{
          id: Age.id(),
          label: Age.label(),
          properties: Age.properties()
        }

  @doc """
  Generate cypher for this Vertex.
  """
  @spec to_cypher(t(), Age.alias(), list()) :: String.t()
  def to_cypher(%__MODULE__{} = vertex, alias \\ nil, keys \\ []) do
    label = Age.label_to_cypher(vertex.label)
    properties = Age.map_to_cypher(vertex.properties, keys)

    "(" <> to_string(alias) <> label <> properties <> ")"
  end
end
