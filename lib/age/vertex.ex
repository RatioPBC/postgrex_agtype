defmodule Age.Vertex do
  @moduledoc """
  Struct representing a Vertex in an AGE graph.
  """

  defstruct [:id, :alias, :label, properties: %{}]

  @type t :: %__MODULE__{
          alias: Age.alias(),
          id: Age.id(),
          label: Age.label(),
          properties: Age.properties()
        }

  @doc """
  Generate cypher for this Vertex.
  """
  @spec to_cypher(t(), Age.alias(), list()) :: String.t()
  def to_cypher(%__MODULE__{} = vertex, alias \\ nil, keys \\ []) do
    alias = alias || vertex.alias
    if is_nil(alias), do: raise(ArgumentError, "vertex alias value required")

    label = Age.label_to_cypher(vertex.label)
    properties = Age.map_to_cypher(vertex.properties, keys)

    "(" <> to_string(alias) <> label <> properties <> ")"
  end
end
