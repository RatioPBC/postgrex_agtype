defmodule PostgrexAgtype do
  @moduledoc """
  # PostgrexAgtype

  A Postgrex extension to support the `agtype` of [AGE](https://age.apache.org).
  """

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

  defp maybe_combine_result(result, combine: true) do
    results = List.flatten(result)
    combined = Graph.new()

    Enum.reduce(results, combined, fn
      %Graph{} = graph, combined ->
        combined =
          graph
          |> Graph.vertices()
          |> Enum.reduce(combined, &Graph.add_vertex(&2, &1, Graph.vertex_labels(graph, &1)))

        graph
        |> Graph.edges()
        |> Enum.reduce(combined, &Graph.add_edge(&2, &1))

      %Graph.Edge{} = edge, combined ->
        Graph.add_edge(combined, edge)

      other, _combined ->
        raise ArgumentError, "`:combine` option used with non-Graph results: #{inspect(other)}"
    end)
  end

  defp maybe_combine_result(result, []) do
    case result do
      [[result]] -> result
      [result] -> result
      _ -> result
    end
  end

  defmacro cypher(graph, query) do
    quote do
      fragment("cypher(?, ?) AS (result agtype)", unquote(graph), unquote(query))
    end
  end
end
