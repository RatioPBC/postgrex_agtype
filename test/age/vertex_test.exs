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
      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert %Vertex{id: @valid_id, graph: %Graph{} = g} = v
      assert Graph.has_vertex?(g, @valid_id)
    end

    test "creates vertex in graph" do
      g = Graph.new()
      refute Graph.has_vertex?(g, @valid_id)

      v = Vertex.new(g, @valid_id, @valid_label, @valid_props)

      assert Graph.has_vertex?(v.graph, @valid_id)
      assert Vertex.label(v) == @valid_label
      assert Vertex.properties(v) == @valid_props
    end

    test "updates vertex in graph" do
      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      v = Vertex.new(v.graph, @valid_id, @update_label, @update_props)

      assert Graph.has_vertex?(v.graph, @valid_id)
      assert Vertex.label(v) == @update_label
      assert Vertex.properties(v) == @update_props
    end
  end

  describe "from/2" do
    test "returns struct" do
      %Vertex{graph: g} = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      v = Vertex.from(g, @valid_id)

      assert %Vertex{id: @valid_id, graph: ^g} = v
    end

    test "raises on absent vertex id" do
      assert_raise ArgumentError, fn ->
        Vertex.from(Graph.new(), @valid_id)
      end
    end
  end

  describe "alias/1" do
    test "returns alias" do
      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props, :a)
      assert Vertex.alias(v) == :a

      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props, "a")
      assert Vertex.alias(v) == "a"

      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)
      assert is_nil(Vertex.alias(v))
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.alias(v)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.alias(v)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.alias(v)
      end
    end
  end

  describe "label/1" do
    test "returns label" do
      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Vertex.label(v) == @valid_label
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.label(v)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.label(v)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.label(v)
      end
    end
  end

  describe "properties/1" do
    test "returns properties" do
      v = Vertex.new(Graph.new(), @valid_id, @valid_label, @valid_props)

      assert Vertex.properties(v) == @valid_props
    end

    test "raises if key not found" do
      g = Graph.new() |> Graph.add_vertex(@valid_id, %{})
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise KeyError, fn ->
        Vertex.properties(v)
      end
    end

    test "raises on bad graph vertex labels" do
      g = Graph.new() |> Graph.add_vertex(@valid_id)
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise EmptyVertexLabelsError, fn ->
        Vertex.properties(v)
      end

      g = Graph.new() |> Graph.add_vertex(@valid_id, [%{}, %{}])
      v = %Vertex{id: @valid_id, graph: g}

      assert_raise MultipleVertexLabelsError, fn ->
        Vertex.properties(v)
      end
    end
  end

  describe "to_cypher/1" do
    test "works with alias" do
      v = Vertex.new(Graph.new(), 123, "Vertex", %{}, :v)
      assert Vertex.to_cypher(v) == "(v:Vertex)"

      v = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"}, :v)
      assert Vertex.to_cypher(v) == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "works with given alias" do
      v = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})
      assert Vertex.to_cypher(v, :v) == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
      assert Vertex.to_cypher(v, "v") == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "raises without alias" do
      v = Vertex.new(Graph.new(), 123, "Vertex", %{b: true, f: 1.1, i: 1, s: "a"})

      assert_raise ArgumentError, fn ->
        assert Vertex.to_cypher(v)
      end
    end
  end
end
