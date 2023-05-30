defmodule Age.VertexTest do
  use PostgrexAgtype.DataCase

  alias Age.Vertex

  describe "to_cypher/2" do
    test "works with given alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Vertex.to_cypher(v, :v) == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
      assert Vertex.to_cypher(v, "v") == "(v:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end

    test "works without alias" do
      v = %Vertex{id: 123, label: "Vertex", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Vertex.to_cypher(v) == "(:Vertex {b:true,f:1.1,i:1,s:'a'})"
    end
  end
end
