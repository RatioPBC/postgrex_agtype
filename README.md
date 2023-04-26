# PostgrexAgtype

A Postgrex.Extension to support Apache AGE `agtype` using [`libgraph`](https://github.com/bitwalker/libgraph).

## Usage

Add this package as a dependency:

```elixir
    {:postgrex_agtype, "~> 0.1.0"}
```

Add an extension file to your code base, specifying JSON parser of choice:

`lib/example/postgrex_types.ex`:
```elixir
Postgrex.Types.define(
  Example.PostgresTypes,
  [PostgrexAgtype.Extension],
  json: Jason
)
```

Query a graph type from the server:

```
SELECT *
FROM cypher('example_graph', $$
    WITH [
        {id: 0, label: "label_name_1", properties: {i: 0}}::vertex,
        {id: 2, start_id: 0, end_id: 1, label: "edge_label", properties: {i: 0}}::edge,
        {id: 1, label: "label_name_2", properties: {}}::vertex
    ]::path as p

    RETURN p
$$) AS (result agtype)
```

```
#Graph<type: directed, vertices: [1, 0], edges: [0 -[%{"id" => 2, "label" => "edge_label", "properties" => %{"i" => 0}}]-> 1]>
```
