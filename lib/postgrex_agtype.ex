defmodule PostgrexAgtype do
  @moduledoc """
  # PostgrexAgtype

  A Postgrex extension to support the `agtype` of [AGE](https://age.apache.org).
  """

  @doc """
  Wraps cypher query in PostgreSQL SELECT statement with optional result name,
  then calls `Postgrex.query/3`.

  ## Examples

      iex> PostgrexAgtype.query(conn, "example_graph") do
        match node(:n)
        return :n
      end
      {:ok, %Posgrex.Result{rows: [[%Graph{...}]], ...}}
  """
  def query(conn, graph, query),
    do: Postgrex.query(conn, wrap_query(query, graph), [])

  @doc """
  Wraps cypher query in PostgreSQL SELECT statement with optional result name,
  then calls `Postgrex.query!/3`.

  ## Examples

      iex> PostgrexAgtype.query!(conn, "example_graph") do
        match node(:n)
        return :n
      end
      %Posgrex.Result{rows: [[%Graph{...}]], ...}
  """
  def query!(conn, graph, query),
    do: Postgrex.query!(conn, wrap_query(query, graph), [])

  def wrap_query(query, graph),
    do: "SELECT * FROM cypher('#{graph}', $$#{query}$$) AS (result agtype)"
end
