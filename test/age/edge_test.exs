defmodule Age.EdgeTest do
  use PostgrexAgtype.DataCase

  alias Age.Edge

  @valid_id 42
  @valid_label "SomeLabel"
  @valid_props %{"some key" => "some value", "weight" => 10}

  @update_label "UpdateLabel"
  @update_props %{"some key" => "some other value", "weight" => 20}

  describe "new/4" do
    test "returns struct" do
      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)

      l = %{
        "alias" => nil,
        "id" => @valid_id,
        "label" => @valid_label,
        "properties" => Map.drop(@valid_props, ["weight"])
      }

      assert %Edge{id: @valid_id, v1: 1, v2: 2, graph: graph} = e
      assert Graph.edge(graph, 1, 2, l) == %Graph.Edge{v1: 1, v2: 2, label: l, weight: 10}
    end

    test "creates edge in graph" do
      g = Graph.new()
      assert Graph.edges(g, 1, 2) == []

      e = Edge.new(g, 1, 2, @valid_id, @valid_label, @valid_props)

      props_without_weight = Map.drop(@valid_props, ["weight"])

      assert [
               %Graph.Edge{
                 v1: 1,
                 v2: 2,
                 label: %{
                   "alias" => nil,
                   "id" => @valid_id,
                   "label" => @valid_label,
                   "properties" => ^props_without_weight
                 },
                 weight: 10
               }
             ] = Graph.edges(e.graph, 1, 2)

      assert Edge.label(e) == @valid_label
      assert Edge.properties(e) == @valid_props
    end

    test "updates vertex in graph" do
      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)
      e = Edge.new(e.graph, 1, 2, @valid_id, @update_label, @update_props)

      props_without_weight = Map.drop(@update_props, ["weight"])

      assert [
               %Graph.Edge{
                 v1: 1,
                 v2: 2,
                 label: %{
                   "alias" => nil,
                   "id" => @valid_id,
                   "label" => @update_label,
                   "properties" => ^props_without_weight
                 },
                 weight: 20
               }
             ] = Graph.edges(e.graph, 1, 2)

      assert Edge.label(e) == @update_label
      assert Edge.properties(e) == @update_props
    end
  end

  describe "from/2" do
    test "returns struct" do
      %Edge{graph: g} = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)
      e = Edge.from(g, 1, 2, @valid_id)

      assert %Edge{id: @valid_id, graph: ^g, v1: 1, v2: 2} = e
    end

    test "raises on absent edge id" do
      assert_raise ArgumentError, fn ->
        Edge.from(Graph.new(), 1, 2, @valid_id)
      end
    end
  end

  describe "alias/1" do
    test "returns alias" do
      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props, :a)
      assert Edge.alias(e) == :a

      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props, "a")
      assert Edge.alias(e) == "a"

      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)
      assert is_nil(Edge.alias(e))
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_edge(1, 2, label: %{"id" => @valid_id, "properties" => %{}})
      e = %Edge{id: @valid_id, v1: 1, v2: 2, graph: g}

      assert_raise KeyError, fn ->
        Edge.alias(e)
      end
    end
  end

  describe "label/1" do
    test "returns label" do
      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)

      assert Edge.label(e) == @valid_label
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_edge(1, 2, label: %{"id" => @valid_id, "properties" => %{}})
      e = %Edge{id: @valid_id, v1: 1, v2: 2, graph: g}

      assert_raise KeyError, fn ->
        Edge.label(e)
      end
    end
  end

  describe "properties/1" do
    test "returns properties" do
      e = Edge.new(Graph.new(), 1, 2, @valid_id, @valid_label, @valid_props)

      assert Edge.properties(e) == @valid_props
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_edge(1, 2, label: %{"id" => @valid_id})
      e = %Edge{id: @valid_id, v1: 1, v2: 2, graph: g}

      assert_raise ArgumentError, fn ->
        Edge.properties(e)
      end
    end
  end

  describe "to_cypher/1" do
    test "works with alias" do
      e = Edge.new(Graph.new(), 1, 2, 123, "Edge", %{}, :e)
      assert Edge.to_cypher(e) == "[e:Edge {weight:1}]"

      e = Edge.new(Graph.new(), 1, 2, 123, "Edge", %{b: true, f: 1.1, i: 1, s: "a"}, :e)
      assert Edge.to_cypher(e) == "[e:Edge {b:true,f:1.1,i:1,s:'a',weight:1}]"
    end

    test "works with given alias" do
      e = Edge.new(Graph.new(), 1, 2, 123, "Edge", %{b: true, f: 1.1, i: 1, s: "a"})
      assert Edge.to_cypher(e, :e) == "[e:Edge {b:true,f:1.1,i:1,s:'a',weight:1}]"
      assert Edge.to_cypher(e, "e") == "[e:Edge {b:true,f:1.1,i:1,s:'a',weight:1}]"
    end

    test "raises without alias" do
      e = Edge.new(Graph.new(), 1, 2, 123, "Edge", %{b: true, f: 1.1, i: 1, s: "a"})

      assert_raise ArgumentError, fn ->
        assert Edge.to_cypher(e)
      end
    end
  end
end
