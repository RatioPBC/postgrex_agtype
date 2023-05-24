defmodule AgeTest do
  use ExUnit.Case, async: true
  doctest Age

  alias Age.{Edge, Vertex}

  describe "wrap_properties/1" do
    test "raises on invalid values" do
      assert_raise ArgumentError, fn ->
        Age.wrap_properties(%{})
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties([])
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(true)
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(123)
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(123.45)
      end
    end
  end

  describe "quote_string/1" do
    test "raises on invalid values" do
      assert_raise ArgumentError, fn ->
        Age.quote_string(%{})
      end

      assert_raise ArgumentError, fn ->
        Age.quote_string([])
      end
    end
  end

  describe "edge_to_cypher/4" do
    test "works with aliases" do
      v1 = Vertex.new(Graph.new(), 1, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"}, :v1)
      v2 = Vertex.new(v1.graph, 2, "Vertex", %{b: false, f: 2.3, i: 4, s: "zzz"}, :v2)
      e = Edge.new(v2.graph, 1, 2, 123, "Edge", %{b: true, f: 6.6, i: 6, s: "mno"}, :e)

      assert Age.edge_to_cypher(e) ==
               "(v1:Vertex {b:true,f:1.1,i:1,s:'a'})" <>
                 "-[e:Edge {b:true,f:6.6,i:6,s:'mno',weight:1}]->" <>
                 "(v2:Vertex {b:false,f:2.3,i:4,s:'zzz'})"
    end

    test "works with given aliases" do
      v1 = Vertex.new(Graph.new(), 1, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})
      v2 = Vertex.new(v1.graph, 2, "Vertex", %{b: false, f: 2.3, i: 4, s: "zzz"})
      e = Edge.new(v2.graph, 1, 2, 123, "Edge", %{b: true, f: 6.6, i: 6, s: "mno"})

      assert Age.edge_to_cypher(e, :e, "v1", :v2) ==
               "(v1:Vertex {b:true,f:1.1,i:1,s:'a'})" <>
                 "-[e:Edge {b:true,f:6.6,i:6,s:'mno',weight:1}]->" <>
                 "(v2:Vertex {b:false,f:2.3,i:4,s:'zzz'})"
    end

    test "raises without aliases" do
      v1 = Vertex.new(Graph.new(), 1, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})
      v2 = Vertex.new(v1.graph, 2, "Vertex", %{b: false, f: 2.3, i: 4, s: "zzz"})
      e = Edge.new(v2.graph, 1, 2, 123, "Edge", %{b: true, f: 6.6, i: 6, s: "mno"})

      assert_raise ArgumentError, fn ->
        assert Age.edge_to_cypher(e)
      end

      assert_raise ArgumentError, fn ->
        assert Age.edge_to_cypher(e, :e)
      end

      assert_raise ArgumentError, fn ->
        assert Age.edge_to_cypher(e, :e, "v1")
      end

      assert_raise ArgumentError, fn ->
        assert Age.edge_to_cypher(e, nil, "v1", :v2)
      end
    end
  end
end
