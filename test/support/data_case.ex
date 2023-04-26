defmodule PostgrexAgtype.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  @graph_name "postgrexagtype_test"

  using do
    quote do
      import PostgrexAgtype.DataCase
    end
  end

  def setup_postgrex(_) do
    opts = Application.fetch_env!(:postgrex_agtype, :postage)

    {:ok, conn} = Postgrex.start_link(opts)

    exec!(conn, "CREATE EXTENSION IF NOT EXISTS age")
    exec!(conn, "GRANT USAGE ON SCHEMA ag_catalog TO #{opts[:username]}")
    exec!(conn, "ALTER ROLE #{opts[:username]} SET search_path = ag_catalog, \"$user\", public")
    exec!(conn, "SET search_path = ag_catalog, \"$user\", public")
    exec!(conn, "LOAD 'age'")

    %{conn: conn}
  end

  def create_graph(%{conn: conn}) do
    try do
      exec!(conn, "SELECT * FROM drop_graph('#{@graph_name}', true)")
    rescue
      _ in Postgrex.Error ->
        nil
    end

    exec!(conn, "SELECT * FROM ag_catalog.create_graph('#{@graph_name}')")

    %{graph_name: @graph_name}
  end

  defp exec!(conn, query), do: Postgrex.query!(conn, query, [])
end
