defmodule Age.VertexTest do
  use PostgrexAgtype.DataCase

  alias Age.Vertex

  describe "to_cypher/2" do
    test "works with set alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{}, alias: :v}
      assert Vertex.to_cypher(v) == "(v:Vertex)"

      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}, alias: :v}
      assert Vertex.to_cypher(v) == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "works with given alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Vertex.to_cypher(v, :v) == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
      assert Vertex.to_cypher(v, "v") == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "given alias overrides set alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}, alias: :v}
      assert Vertex.to_cypher(v, :z) == "(z:Vertex {b:true,f:1.1,i:1,s:'a'})"
      assert Vertex.to_cypher(v, "z") == "(z:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "raises without alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}}

      assert_raise ArgumentError, fn ->
        assert Vertex.to_cypher(v)
      end
    end
  end
end
