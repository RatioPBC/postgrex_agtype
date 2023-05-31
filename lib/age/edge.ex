defmodule Age.Edge do
  @moduledoc """
  Struct representing an Edge in an AGE graph.
  """

  defstruct [:alias, :id, :v1, :v2, :label, properties: %{}]

  @type weight :: integer() | float()

  @type t :: %__MODULE__{
          alias: Age.alias(),
          id: Age.id(),
          v1: Age.id(),
          v2: Age.id(),
          label: Age.label(),
          properties: Age.properties()
        }

  @doc """
  Generate cypher for only this Edge.

  ## Examples

      iex> Age.Edge.to_cypher(edge, :e)
      "[e:Label {key:'value',other:123}]"

  """
  @spec to_cypher(t(), Age.alias(), list()) :: String.t()
  def to_cypher(%__MODULE__{} = edge, alias \\ nil, keys \\ []) do
    label = Age.label_to_cypher(edge.label)
    properties = Age.map_to_cypher(edge.properties, keys)

    "[" <> to_string(alias || edge.alias) <> label <> properties <> "]"
  end

  @doc """
  Generate cypher for this Edge with given vertex aliases and arrows.

  ## Examples

      iex> Age.Edge.to_cypher(edge, :e, :x, "y")
      "(x)-[e:Label {key:'value',other:123}]->(y)"

  """
  @spec to_cypher(t(), Age.alias(), Age.alias(), Age.alias()) :: String.t()
  def to_cypher(%__MODULE__{} = edge, alias, v1_alias, v2_alias) do
    "(#{v1_alias})-" <> to_cypher(edge, alias) <> "->(#{v2_alias})"
  end
end
