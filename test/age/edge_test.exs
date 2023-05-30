defmodule Age.EdgeTest do
  use PostgrexAgtype.DataCase

  alias Age.Edge

  describe "to_cypher/2" do
    test "works with set alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{}, alias: :e}
      assert Edge.to_cypher(e) == "[e:Edge]"

      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}, alias: :e}
      assert Edge.to_cypher(e) == "[e:Edge {b:true,f:1.1,i:1,s:'a'}]"
    end

    test "works with given alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e, :e) == "[e:Edge {b:true,f:1.1,i:1,s:'a'}]"
      assert Edge.to_cypher(e, "e") == "[e:Edge {b:true,f:1.1,i:1,s:'a'}]"
    end

    test "given alias overrides set alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}, alias: :e}
      assert Edge.to_cypher(e, :z) == "[z:Edge {b:true,f:1.1,i:1,s:'a'}]"
      assert Edge.to_cypher(e, "z") == "[z:Edge {b:true,f:1.1,i:1,s:'a'}]"
    end

    test "raises without alias" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}

      assert_raise ArgumentError, fn ->
        assert Edge.to_cypher(e)
      end
    end
  end

  describe "to_cypher/4" do
    test "works with given aliases" do
      e = %Edge{v1: 1, v2: 2, id: 123, label: "Edge", properties: %{b: true, f: 1.1, i: 1, s: "a"}}
      assert Edge.to_cypher(e, :e, :a, :b) == "(a)-[e:Edge {b:true,f:1.1,i:1,s:'a'}]->(b)"
    end
  end
end
