defmodule Age.NodeTest do
  use PostgrexAgtype.DataCase

  alias Age.Node
  alias Age.Node.{EmptyVertexLabelsError, MultipleVertexLabelsError}

  @valid_id 42
  @valid_label "SomeLabel"
  @valid_props %{"some key" => "some value"}

  @update_label "UpdateLabel"
  @update_props %{"some key" => "some other value", "other" => 123}

  describe "new/4" do
    test "returns struct" do
      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert %Node{id: @valid_id, graph: %Graph{} = g} = n
      assert Graph.has_vertex?(g, @valid_id)
    end

    test "creates vertex in graph" do
      g = Graph.new()
      refute Graph.has_vertex?(g, @valid_id)

      n = Node.new(g, @valid_id, @valid_label, @valid_props)

      assert Graph.has_vertex?(n.graph, @valid_id)
      assert Node.label(n) == @valid_label
      assert Node.properties(n) == @valid_props
    end

    test "updates vertex in graph" do
      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      n = Node.new(n.graph, @valid_id, @update_label, @update_props)

      assert Graph.has_vertex?(n.graph, @valid_id)
      assert Node.label(n) == @update_label
      assert Node.properties(n) == @update_props
    end
  end

  describe "from/2" do
    test "returns struct" do
      %Node{graph: g} = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      n = Node.from(g, @valid_id)

      assert %Node{id: @valid_id, graph: ^g} = n
    end

    test "raises on absent vertex id" do
      assert_raise ArgumentError, fn ->
        Node.from(Graph.new(), @valid_id)
      end
    end
  end

  describe "alias/1" do
    test "returns alias" do
      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props, :a)
      assert Node.alias(n) == :a

      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props, "a")
      assert Node.alias(n) == "a"

      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      assert is_nil(Node.alias(n))
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Node{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Node.alias(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Node{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Node.alias(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Node{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Node.alias(n)
      end
    end
  end

  describe "label/1" do
    test "returns label" do
      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Node.label(n) == @valid_label
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Node{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Node.label(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Node{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Node.label(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Node{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Node.label(n)
      end
    end
  end

  describe "properties/1" do
    test "returns properties" do
      n = Node.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Node.properties(n) == @valid_props
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Node{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Node.properties(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Node{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Node.properties(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Node{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Node.properties(n)
      end
    end
  end

  describe "to_cypher/1" do
    test "works with alias" do
      n = Node.new(Graph.new(), 123, "Node", %{}, :n)
      assert Node.to_cypher(n) == "(n:Node)"

      n = Node.new(Graph.new(), 123, "Node", %{b: true, f: 1.1, i: 1, s: "a"}, :n)
      assert Node.to_cypher(n) == "(n:Node {b:true,f:1.1,i:1,s:'a'})"
    end

    test "works with given alias" do
      n = Node.new(Graph.new(), 123, "Node", %{b: true, f: 1.1, i: 1, s: "a"})
      assert Node.to_cypher(n, :n) == "(n:Node {b:true,f:1.1,i:1,s:'a'})"
      assert Node.to_cypher(n, "n") == "(n:Node {b:true,f:1.1,i:1,s:'a'})"
    end

    test "raises without alias" do
      n = Node.new(Graph.new(), 123, "Node", %{b: true, f: 1.1, i: 1, s: "a"})

      assert_raise ArgumentError, fn ->
        assert Node.to_cypher(n)
      end
    end
  end
end
