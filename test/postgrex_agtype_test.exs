defmodule PostgrexAgtypeTest do
  use PostgrexAgtype.DataCase

  alias Age.Graph

  setup [:setup_postgrex, :create_graph]

  describe "query!/3" do
    test "combines vertex result rows with combine option", %{conn: conn, graph_name: graph_name} do
      alpha_id = PostgrexAgtype.query!(conn, graph_name, "CREATE (a:Alpha) RETURN ID(a)")
      beta_id = PostgrexAgtype.query!(conn, graph_name, "CREATE (b:Beta {bid: 1}) RETURN ID(b)")

      observed = PostgrexAgtype.query!(conn, graph_name, "MATCH (n) RETURN n", combine: true)

      expected =
        %Graph{}
        |> Graph.add_vertex(alpha_id, "Alpha")
        |> Graph.add_vertex(beta_id, "Beta", %{"bid" => 1})

      assert expected == observed
    end

    test "combines edge result rows with combine option", %{conn: conn, graph_name: graph_name} do
      alpha_id = PostgrexAgtype.query!(conn, graph_name, "CREATE (a:Alpha) RETURN ID(a)")
      beta_id = PostgrexAgtype.query!(conn, graph_name, "CREATE (b:Beta) RETURN ID(b)")

      [e1, e2] =
        PostgrexAgtype.query!(
          conn,
          graph_name,
          "MATCH (a:Alpha), (b:Beta) CREATE (b)-[e1:Rel]->(a), (a)-[e2:Rel]->(b) RETURN [ID(e1), ID(e2)]"
        )

      observed =
        PostgrexAgtype.query!(conn, graph_name, "MATCH ()-[e:Rel]->() RETURN e", combine: true)

      expected =
        %Graph{}
        |> Graph.add_edge(beta_id, alpha_id, e1, "Rel")
        |> Graph.add_edge(alpha_id, beta_id, e2, "Rel")

      assert expected == observed
    end
  end
end
