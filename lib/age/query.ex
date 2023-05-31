defmodule Age.Query do
  @moduledoc """
  Data structure for an entire AGE cypher query.
  """

  @type t :: %__MODULE__{}

  @type entity :: Age.Edge.t() | Age.Vertex.t()

  defstruct create: [],
            delete: nil,
            limit: nil,
            match: [],
            merge: nil,
            order_by: nil,
            remove: nil,
            return: nil,
            set: nil,
            skip: nil,
            where: nil,
            with: nil

  @spec new() :: t()
  def new, do: %__MODULE__{}

  # --- CREATE

  @spec create(t(), Age.Vertex.t(), Age.alias()) :: t()
  def create(%__MODULE__{} = query, vertex, alias),
    do: append(query, :create, {vertex, alias})

  @spec create(t(), Age.Edge.t(), Age.alias(), Age.alias(), Age.alias()) :: t()
  def create(%__MODULE__{} = query, edge, alias, v1_alias, v2_alias),
    do: append(query, :create, {edge, alias, v1_alias, v2_alias})

  # --- MATCH

  @spec match(t(), Age.Vertex.t(), Age.alias()) :: t()
  def match(%__MODULE__{} = query, vertex, alias),
    do: append(query, :match, {vertex, alias})

  @spec match(t(), Age.Edge.t(), Age.alias(), Age.alias(), Age.alias()) :: t()
  def match(%__MODULE__{} = query, edge, alias, v1_alias, v2_alias),
    do: append(query, :match, {edge, alias, v1_alias, v2_alias})

  # --- RETURN

  @spec return(t(), atom() | list()) :: t()
  def return(%__MODULE__{} = query, atom) when is_atom(atom),
    do: %__MODULE__{query | return: atom}

  def return(%__MODULE__{} = query, list) when is_list(list),
    do: %__MODULE__{query | return: list}

  defp append(%__MODULE__{} = query, field, value),
    do: Map.put(query, field, Map.get(query, field) ++ [value])

  # ---

  @spec to_cypher(t()) :: String.t()
  def to_cypher(%__MODULE__{} = query) do
    {query, ""}
    |> match_to_cypher()
    |> create_to_cypher()
    |> return_to_cypher()
    |> String.trim()
  end

  defp match_to_cypher({%__MODULE__{match: []} = query, query_string}),
    do: {query, query_string}

  defp match_to_cypher({%__MODULE__{match: matches} = query, query_string}) do
    matches_string = Enum.map_join(matches, ",", &entity_to_cypher/1)

    {query, query_string <> " MATCH " <> matches_string}
  end

  defp create_to_cypher({%__MODULE__{create: []} = query, query_string}),
    do: {query, query_string}

  defp create_to_cypher({%__MODULE__{create: creates} = query, query_string}) do
    creates_string = Enum.map_join(creates, ",", &entity_to_cypher/1)

    {query, query_string <> " CREATE " <> creates_string}
  end

  defp entity_to_cypher({%Age.Edge{} = edge, alias, v1_alias, v2_alias}),
    do: Age.Edge.to_cypher(edge, alias, v1_alias, v2_alias)

  defp entity_to_cypher({%Age.Vertex{} = vertex, alias}),
    do: Age.Vertex.to_cypher(vertex, alias)

  # defp entity_to_cypher({[_ | _] = path, _alias}) do
  #   path
  # end

  defp return_to_cypher({%__MODULE__{return: return}, query_string}) when is_atom(return),
    do: query_string <> " RETURN " <> Atom.to_string(return)

  defp return_to_cypher({%__MODULE__{return: return}, query_string}) when is_list(return),
    do: query_string <> " RETURN [" <> Enum.map_join(return, ",", &Atom.to_string/1) <> "]"
end
