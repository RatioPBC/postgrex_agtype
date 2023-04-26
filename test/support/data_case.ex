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

    Postgrex.query!(conn, "CREATE EXTENSION IF NOT EXISTS age", [])
    Postgrex.query!(conn, "ALTER ROLE postgres SET search_path = ag_catalog, \"$user\", public", [])
    Postgrex.query!(conn, "LOAD 'age'", [])

    %{conn: conn}
  end

  def create_graph(%{conn: conn}) do
    Postgrex.query!(conn, "SELECT * FROM drop_graph('#{@graph_name}', true)", [])
    Postgrex.query!(conn, "SELECT * FROM create_graph('#{@graph_name}')", [])

    %{graph_name: @graph_name}
  end
end
