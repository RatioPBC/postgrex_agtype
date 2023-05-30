defmodule PostgrexAgtype do
  @moduledoc """
  # PostgrexAgtype

  A Postgrex extension to support the `agtype` of [AGE](https://age.apache.org).
  """

  alias Age.{Edge, Graph, Vertex}

  require Logger

  @doc """
  Wraps cypher query in PostgreSQL SELECT statement with optional result name,
  then calls `Postgrex.query/3`.

  ## Examples

      iex> PostgrexAgtype.query(conn, "example_graph", "MATCH (n) RETURN n")
      {:ok, %Postgrex.Result{rows: [[%Graph{...}]], ...}}

      iex> PostgrexAgtype.query(conn, "example_graph", "MATCH (n) RETURN n", combine: true)
      {:ok, %Graph{...}}

  """
  def query(conn, graph, query, opts \\ []) do
    conn
    |> Postgrex.query(wrap_query(query, graph), [])
    |> handle_postgrex_result(opts)
  end

  @doc """
  Wraps cypher query in PostgreSQL SELECT statement with optional result name,
  then calls `Postgrex.query!/3`.

  ## Examples

      iex> PostgrexAgtype.query!(conn, "example_graph", "MATCH (n) RETURN n")
      %Postgrex.Result{rows: [[%Graph{...}]], ...}

      iex> PostgrexAgtype.query!(Repo, "example_graph", "MATCH (n) RETURN n", combine: true)
      %Graph{...}

  """
  def query!(conn_or_repo, graph, query, opts \\ [])

  def query!(conn_or_repo, graph, query, opts) when is_pid(conn_or_repo) do
    conn_or_repo
    |> Postgrex.query!(wrap_query(query, graph), [])
    |> handle_postgrex_result(opts)
  end

  def query!(conn_or_repo, graph, query, opts) when is_atom(conn_or_repo) do
    query
    |> wrap_query(graph)
    |> conn_or_repo.query!()
    |> handle_postgrex_result(opts)
  end

  def cypher_query!(%Age.Query{} = query, conn_or_repo, graph, opts \\ []) do
    cypher = Age.Query.to_cypher(query)

    Logger.debug(cypher)

    query!(conn_or_repo, graph, cypher, opts)
  end

  # ---

  def wrap_query(query, graph),
    do: "SELECT * FROM cypher('#{graph}', $$#{query}$$) AS (result agtype)"

  # ---

  defp handle_postgrex_result({:ok, %Postgrex.Result{rows: result}}, opts),
    do: {:ok, maybe_combine_result(result, opts)}

  defp handle_postgrex_result(%Postgrex.Result{rows: result}, opts),
    do: maybe_combine_result(result, opts)

  defp handle_postgrex_result({:error, _} = error, _opts), do: error

  # ---

  defp maybe_combine_result(result, opts) do
    if Keyword.get(opts, :combine, false) do
      combine_result(result)
    else
      extract_result(result)
    end
  end

  defp extract_result(result) do
    case result do
      [[result]] -> result
      [result] -> result
      _ -> result
    end
  end

  defp combine_result(result) do
    result
    |> List.flatten()
    |> Enum.reduce(%Graph{}, &reduce_result/2)
  end

  defp reduce_result(%Edge{} = edge, combined), do: Graph.add_edge(combined, edge)

  defp reduce_result(%Graph{} = graph, combined) do
    combined
    |> reduce_graph_vertices(graph)
    |> reduce_graph_edges(graph)
  end

  defp reduce_result(%Vertex{} = vertex, combined), do: Graph.add_vertex(combined, vertex)

  defp reduce_graph_edges(combined, %Graph{edges: edges}),
    do: Enum.reduce(edges, combined, &Graph.add_edge(&2, &1))

  defp reduce_graph_vertices(combined, %Graph{vertices: vertices}),
    do: Enum.reduce(vertices, combined, &Graph.add_vertex(&2, &1))
end
