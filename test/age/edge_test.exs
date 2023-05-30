defmodule Age.EdgeTest do
  use PostgrexAgtype.DataCase

  alias Age.Edge

  describe "to_cypher/2" do
    test "works with given alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e, :e) == "[e:Edge {b:true,f:1.1,i:1,s:'a'}]"
      assert Edge.to_cypher(e, "e") == "[e:Edge {b:true,f:1.1,i:1,s:'a'}]"
    end

    test "works without alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e) == "[:Edge {b:true,f:1.1,i:1,s:'a'}]"
    end
  end

  describe "to_cypher/4" do
    test "works with given aliases" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e, :e, :a, :b) == "(a)-[e:Edge {b:true,f:1.1,i:1,s:'a'}]->(b)"
    end

    test "works with nil aliases" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e, nil, nil, nil) == "()-[:Edge {b:true,f:1.1,i:1,s:'a'}]->()"
    end
  end
end
