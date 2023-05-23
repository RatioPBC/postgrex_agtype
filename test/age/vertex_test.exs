defmodule Age.VertexTest do
  use PostgrexAgtype.DataCase

  alias Age.Vertex
  alias Age.Vertex.{EmptyVertexLabelsError, MultipleVertexLabelsError}

  @valid_id 42
  @valid_label "SomeLabel"
  @valid_props %{"some key" => "some value"}

  @update_label "UpdateLabel"
  @update_props %{"some key" => "some other value", "other" => 123}

  describe "new/4" do
    test "returns struct" do
      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert %Vertex{id: @valid_id, graph: %Graph{} = g} = n
      assert Graph.has_vertex?(g, @valid_id)
    end

    test "creates vertex in graph" do
      g = Graph.new()
      refute Graph.has_vertex?(g, @valid_id)

      n = Vertex.new(g, @valid_id, @valid_label, @valid_props)

      assert Graph.has_vertex?(n.graph, @valid_id)
      assert Vertex.label(n) == @valid_label
      assert Vertex.properties(n) == @valid_props
    end

    test "updates vertex in graph" do
      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      n = Vertex.new(n.graph, @valid_id, @update_label, @update_props)

      assert Graph.has_vertex?(n.graph, @valid_id)
      assert Vertex.label(n) == @update_label
      assert Vertex.properties(n) == @update_props
    end
  end

  describe "from/2" do
    test "returns struct" do
      %Vertex{graph: g} = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      n = Vertex.from(g, @valid_id)

      assert %Vertex{id: @valid_id, graph: ^g} = n
    end

    test "raises on absent vertex id" do
      assert_raise ArgumentError, fn ->
        Vertex.from(Graph.new(), @valid_id)
      end
    end
  end

  describe "alias/1" do
    test "returns alias" do
      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props, :a)
      assert Vertex.alias(n) == :a

      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props, "a")
      assert Vertex.alias(n) == "a"

      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      assert is_nil(Vertex.alias(n))
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.alias(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.alias(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.alias(n)
      end
    end
  end

  describe "label/1" do
    test "returns label" do
      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Vertex.label(n) == @valid_label
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.label(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.label(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.label(n)
      end
    end
  end

  describe "properties/1" do
    test "returns properties" do
      n = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Vertex.properties(n) == @valid_props
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.properties(n)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.properties(n)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      n = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.properties(n)
      end
    end
  end

  describe "to_cypher/1" do
    test "works with alias" do
      n = Vertex.new(Graph.new(), 123, "Vertex", %{}, :n)
      assert Vertex.to_cypher(n) == "(n:Vertex)"

      n = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"}, :n)
      assert Vertex.to_cypher(n) == "(n:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "works with given alias" do
      n = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})
      assert Vertex.to_cypher(n, :n) == "(n:Vertex {b:true,f:1.1,i:1,s:'a'})"
      assert Vertex.to_cypher(n, "n") == "(n:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "raises without alias" do
      n = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})

      assert_raise ArgumentError, fn ->
        assert Vertex.to_cypher(n)
      end
    end
  end
end
