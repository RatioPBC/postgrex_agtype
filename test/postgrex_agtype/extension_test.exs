defmodule PostgrexAgtype.ExtensionTest do
  use PostgrexAgtype.DataCase

  setup [:setup_postgrex, :create_graph]

  def test_cypher_query(context) do
    %{
      conn: conn,
      cypher: cypher,
      expected: expected,
      graph_name: graph_name
    } = context

    query = """
    SELECT *
    FROM cypher('#{graph_name}', $$
      #{cypher}
    $$) AS (result agtype)
    """

    assert %Postgrex.Result{rows: [[observed]]} = Postgrex.query!(conn, query, [])
    assert expected == observed
  end

  describe "local testing setup" do
    test "connection", %{conn: conn} do
      assert %Postgrex.Result{rows: [[1]]} = Postgrex.query!(conn, "SELECT 1", [])
    end
  end

  describe "decodes simple data types" do
    setup [:create_graph]

    @tag cypher: "RETURN NULL", expected: nil
    test "of null", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: "RETURN 1", expected: 1
    test "of integer", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: "RETURN 1.0", expected: 1.0
    test "of float", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: "RETURN 3.14::numeric", expected: Decimal.new("3.14")
    test "of numeric", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: "RETURN 'This is a string'", expected: "This is a string"
    test "of string", ctx do
      test_cypher_query(ctx)
    end
  end

  describe "decodes composite data types" do
    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst
         """,
         expected: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    test "of list", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [null] as lst
         RETURN lst
         """,
         expected: [nil]
    test "of null in a list", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[3]
         """,
         expected: 3
    test "of list access", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, {key: 'key_value'}, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst
         """,
         expected: [0, %{"key" => "key_value"}, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    test "of maps in lists", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, {key: 'key_value'}, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[1].key
         """,
         expected: "key_value"
    test "of map access in lists", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[-3]
         """,
         expected: 8
    test "of negative list access", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[0..3]
         """,
         expected: [0, 1, 2]
    test "of list ranges", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[0..-5]
         """,
         expected: [0, 1, 2, 3, 4, 5]
    test "of negative list ranges", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[..4]
         """,
         expected: [0, 1, 2, 3]
    test "of positive list slice", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[-5..]
         """,
         expected: [6, 7, 8, 9, 10]
    test "of negative list slice", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[15]
         """,
         expected: nil
    test "of out of bounds index", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[5..15]
         """,
         expected: [5, 6, 7, 8, 9, 10]
    test "of out of bounds slice", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH {int_key: 1, float_key: 1.0, numeric_key: 1::numeric, bool_key: true, string_key: 'Value'} as m
         RETURN m
         """,
         expected: %{
           "int_key" => 1,
           "bool_key" => true,
           "float_key" => 1.0,
           "numeric_key" => Decimal.new("1"),
           "string_key" => "Value"
         }
    test "literal maps with simple data types", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH {listKey: [{inner: 'Map1'}, {inner: 'Map2'}], mapKey: {i: 0}} as m
         RETURN m
         """,
         expected: %{
           "listKey" => [
             %{"inner" => "Map1"},
             %{"inner" => "Map2"}
           ],
           "mapKey" => %{"i" => 0}
         }
    test "literal maps with composite data types", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH {int_key: 1, float_key: 1.0, numeric_key: 1::numeric, bool_key: true, string_key: 'Value'} as m
         RETURN m.int_key
         """,
         expected: 1
    test "property access of a map", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH {listKey: [{inner: 'Map1'}, {inner: 'Map2'}], mapKey: {i: 0}} as m
         RETURN m.listKey[0]
         """,
         expected: %{"inner" => "Map1"}
    test "accessing list element in map", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
           WITH {id: 0, label: "label_name", properties: {i: 0}}::vertex as v
           RETURN v
         """,
         expected:
           Graph.new()
           |> Graph.add_vertex(0, %{"label" => "label_name", "properties" => %{"i" => 0}})
    test "casting map to vertex", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH {id: 2, start_id: 0, end_id: 1, label: "label_name", properties: {i: 0}}::edge as e
         RETURN e
         """,
         expected:
           Graph.new()
           |> Graph.add_edge(
             Graph.Edge.new(0, 1,
               label: %{"id" => 2, "label" => "label_name", "properties" => %{"i" => 0}}
             )
           )
    test "casting map to edge", ctx do
      test_cypher_query(ctx)
    end

    @tag cypher: """
         WITH [
           {id: 0, label: "label_name_1", properties: {i: 0}}::vertex,
           {id: 2, start_id: 0, end_id: 1, label: "edge_label", properties: {i: 0}}::edge,
           {id: 1, label: "label_name_2", properties: {}}::vertex
         ]::path as p
         RETURN p
         """,
         expected:
           Graph.new()
           |> Graph.add_vertex(0, %{"label" => "label_name_1", "properties" => %{"i" => 0}})
           |> Graph.add_vertex(1, %{"label" => "label_name_2", "properties" => %{}})
           |> Graph.add_edge(
             Graph.Edge.new(0, 1,
               id: 2,
               label: %{
                 "id" => 2,
                 "label" => "edge_label",
                 "properties" => %{"i" => 0}
               }
             )
           )
    test "casting list to path", ctx do
      test_cypher_query(ctx)
    end

    test "returns single Graph for single row result", %{conn: conn, graph_name: graph_name} do
      create_alpha_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        CREATE (a:Alpha)
        RETURN ID(a)
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[alpha_id]]} = Postgrex.query!(conn, create_alpha_query, [])

      create_betas_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        MATCH (a:Alpha)
        WHERE ID(a) = #{alpha_id}
        CREATE (b1:Beta {bid: 1})-[e1:Rel]->(a), (b2:Beta {bid: 2})-[e2:Rel]->(a)
        RETURN [ID(b1), ID(b2), ID(e1), ID(e2)]
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[[bid1, bid2, eid1, eid2]]]} =
        Postgrex.query!(conn, create_betas_query, [])

      query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        MATCH (b1:Beta)-[e1:Rel]->(a:Alpha), (b2:Beta)-[e2:Rel]->(a:Alpha)
        WHERE ID(e1) = #{eid1} AND ID(e2) = #{eid2}
        RETURN [b1, e1, a, b2, e2]
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[observed]]} = Postgrex.query!(conn, query, [])

      expected =
        Graph.new()
        |> Graph.add_vertex(alpha_id, %{"label" => "Alpha", "properties" => %{}})
        |> Graph.add_vertex(bid1, %{"label" => "Beta", "properties" => %{"bid" => 1}})
        |> Graph.add_vertex(bid2, %{"label" => "Beta", "properties" => %{"bid" => 2}})
        |> Graph.add_edge(bid1, alpha_id,
          label: %{"id" => eid1, "label" => "Rel", "properties" => %{}}
        )
        |> Graph.add_edge(bid2, alpha_id,
          label: %{"id" => eid2, "label" => "Rel", "properties" => %{}}
        )

      assert expected == observed
    end

    test "returns a graph for each row in result", %{conn: conn, graph_name: graph_name} do
      create_alpha_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        CREATE (a:Alpha)
        RETURN ID(a)
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[alpha_id]]} = Postgrex.query!(conn, create_alpha_query, [])

      create_beta_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        CREATE (b:Beta {bid: 1})
        RETURN ID(b)
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[beta_id]]} = Postgrex.query!(conn, create_beta_query, [])

      query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        MATCH (n)
        RETURN n
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: observed} = Postgrex.query!(conn, query, [])

      expected = [
        [Graph.add_vertex(Graph.new(), alpha_id, %{"label" => "Alpha", "properties" => %{}})],
        [
          Graph.add_vertex(Graph.new(), beta_id, %{
            "label" => "Beta",
            "properties" => %{"bid" => 1}
          })
        ]
      ]

      assert expected == observed
    end

    test "returns single Graph for single edge result", %{conn: conn, graph_name: graph_name} do
      create_alpha_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        CREATE (a:Alpha)
        RETURN ID(a)
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[alpha_id]]} = Postgrex.query!(conn, create_alpha_query, [])

      create_betas_query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        MATCH (a:Alpha)
        WHERE ID(a) = #{alpha_id}
        CREATE (b1:Beta {bid: 1})-[e1:Rel]->(a)
        RETURN [ID(b1), ID(e1)]
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[[bid, eid]]]} = Postgrex.query!(conn, create_betas_query, [])

      query = """
      SELECT *
      FROM cypher('#{graph_name}', $$
        MATCH (b:Beta)-[e:Rel]->(a:Alpha)
        WHERE ID(e) = #{eid}
        RETURN e
      $$) AS (result agtype)
      """

      %Postgrex.Result{rows: [[observed]]} = Postgrex.query!(conn, query, [])

      expected =
        Graph.add_edge(Graph.new(), bid, alpha_id,
          label: %{"id" => eid, "label" => "Rel", "properties" => %{}}
        )

      assert expected == observed
    end
  end

  # describe "encodes graph structs" do
  #   setup [:create_graph]

  #   test "with a single vertex", %{conn: conn, graph_name: graph_name} do
  #     graph =
  #       Graph.new()
  #       |> Graph.add_vertex(0, %{"label" => "label_name", "properties" => %{"i" => 0}})

  #     query = """
  #     SELECT *
  #     FROM cypher('#{graph_name}', $$
  #       #{cypher}
  #     $$) AS (result agtype)
  #     """

  #     assert %Postgrex.Result{rows: [[observed]]} = Postgrex.query!(conn, query, [])
  #     assert expected == observed
  #   end
  # end
end
