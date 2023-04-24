defmodule PostgrexAgtype.ExtensionTest do
  use PostgrexAgtype.DataCase

  setup [:setup_postgrex]

  def test_simple_data_type(context) do
    %{
      conn: conn,
      expected: expected,
      graph_name: graph_name,
      value: value
    } = context

    query = """
    SELECT *
    FROM cypher('#{graph_name}', $$
      RETURN #{value}
    $$) AS (result agtype)
    """

    assert %Postgrex.Result{rows: [[^expected]]} = Postgrex.query!(conn, query, [])
  end

  describe "local testing setup" do
    test "connection", %{conn: conn} do
      assert %Postgrex.Result{rows: [[1]]} = Postgrex.query!(conn, "SELECT 1", [])
    end
  end

  describe "handles simple data type" do
    setup [:create_graph]

    @tag value: "NULL", expected: nil
    test "of null", ctx do
      test_simple_data_type(ctx)
    end

    @tag value: "1", expected: 1
    test "of integer", ctx do
      test_simple_data_type(ctx)
    end

    @tag value: "1.0", expected: 1.0
    test "of float", ctx do
      test_simple_data_type(ctx)
    end

    @tag value: "3.14::numeric", expected: Decimal.new("3.14")
    test "of numeric", ctx do
      test_simple_data_type(ctx)
    end

    @tag value: "'This is a string'", expected: "This is a string"
    test "of string", ctx do
      test_simple_data_type(ctx)
    end
  end

  def test_composite_data_type(context) do
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

    IO.inspect(expected, label: "expected")

    assert %Postgrex.Result{rows: [[^expected]]} = Postgrex.query!(conn, query, [])
  end

  describe "handles composite data type" do
    setup [:create_graph]

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst
         """,
         expected: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    test "of list", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [null] as lst
         RETURN lst
         """,
         expected: [nil]
    test "of null in a list", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[3]
         """,
         expected: 3
    test "of list access", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, {key: 'key_value'}, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst
         """,
         expected: [0, %{"key" => "key_value"}, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    test "of maps in lists", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, {key: 'key_value'}, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[1].key
         """,
         expected: "key_value"
    test "of map access in lists", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[-3]
         """,
         expected: 8
    test "of negative list access", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[0..3]
         """,
         expected: [0, 1, 2]
    test "of list ranges", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[0..-5]
         """,
         expected: [0, 1, 2, 3, 4, 5]
    test "of negative list ranges", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[..4]
         """,
         expected: [0, 1, 2, 3]
    test "of positive list slice", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[-5..]
         """,
         expected: [6, 7, 8, 9, 10]
    test "of negative list slice", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[15]
         """,
         expected: nil
    test "of out of bounds index", ctx do
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as lst
         RETURN lst[5..15]
         """,
         expected: [5, 6, 7, 8, 9, 10]
    test "of out of bounds slice", ctx do
      test_composite_data_type(ctx)
    end

    # NOTE: return map values as numeric literals not supported by this extension.
    #       numeric literals are removed from the following examples.
    #       see: https://age.apache.org/age-manual/master/intro/types.html#literal-maps-with-simple-data-types

    @tag cypher: """
         WITH {int_key: 1, float_key: 1.0, bool_key: true, string_key: 'Value'} as m
         RETURN m
         """,
         expected: %{
           "int_key" => 1,
           "bool_key" => true,
           "float_key" => 1.0,
           "string_key" => "Value"
         }
    test "literal maps with simple data types", ctx do
      test_composite_data_type(ctx)
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
      test_composite_data_type(ctx)
    end

    @tag cypher: """
         WITH {listKey: [{inner: 'Map1'}, {inner: 'Map2'}], mapKey: {i: 0}} as m
         RETURN m.listKey[0]
         """,
         expected: %{"inner" => "Map1"}
    test "accessing list element in map", ctx do
      test_composite_data_type(ctx)
    end
  end
end
