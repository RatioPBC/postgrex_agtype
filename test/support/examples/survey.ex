defmodule PostgrexAgtype.Examples.Survey do
  @moduledoc false

  alias Age.{Edge, Query, Vertex}

  import PostgrexAgtype.DataCase, only: [setup_postgrex: 1, create_graph: 1]

  def setup do
    %{conn: conn} = setup_postgrex(nil)
    %{graph_name: graph_name} = create_graph(%{conn: conn})

    [conn, graph_name]
  end

  def create_survey(conn, graph_name) do
    survey =
      Query.create(%Vertex{label: "Survey", properties: %{name: "Case Investigation"}}, :s)
      |> Query.return(:s)
      |> PostgrexAgtype.cypher_query!(conn, graph_name)

    q1 =
      Query.match(survey, :s)
      |> Query.create(
        %Vertex{
          label: "Question",
          properties: %{
            type: "setting",
            key: "respondent",
            text: "Who is providing this information?"
          }
        },
        :q
      )
      |> Query.create(%Edge{label: "Start"}, :e, :s, :q)
      |> Query.return([:s, :e, :q])
      |> PostgrexAgtype.cypher_query!(conn, graph_name)
  end

  # def old_create_survey(conn, graph_name) do
  #   graph = %Age.Graph{}

  #   survey =
  #     Query.new()
  #     |> Query.create(Vertex.new(graph.graph, -1, "Survey", %{name: "Case Investigation"}), :s)
  #     |> Query.return(:s)
  #     |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #     |> Vertex.from()

  #   q1 =
  #     Query.new()
  #     |> Query.create(
  #       Vertex.new(survey.graph, -2, "Question", %{
  #         type: "setting",
  #         key: "respondent",
  #         text: "Who is providing this information?"
  #       }),
  #       :q
  #     )
  #     |> Query.return(:q)
  #     |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #     |> Vertex.from()

  #   start =
  #     Query.new()
  #     |> Query.match(survey, :s)
  #     |> Query.match(q1, :q)
  #     |> Query.create(Edge.new(q1.graph, -1, -2, -3, "Start", %{}), :e, :s, :q)
  #     |> Query.return([:s, :e, :q])
  #     |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #     |> Edge.from()

  #   q1a1 =
  #     Query.new()
  #     |> Query.match(q1, :q)
  #     |> Query.create(
  #       Vertex.new(start.graph, -4, "Answer", %{text: "Case / Self", value: "self"}),
  #       :a
  #     )
  #     |> Query.create(Edge.new(start.graph, -4, q1.id, -7, "Answers", %{}), :e, :a, :q)
  #     |> Query.return([:a, :e, :q])
  #     |> PostgrexAgtype.cypher_query!(conn, graph_name, inspect_query: true)

  #   # q1a2 =
  #   #   Query.new()
  #   #   |> Query.create(
  #   #     Vertex.new(q1a1.graph, -5, "Answer", %{text: "Contact", value: "contact"}),
  #   #     :a
  #   #   )
  #   #   |> Query.return(:a)
  #   #   |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #   #   |> Vertex.from()

  #   # q1a3 =
  #   #   Query.new()
  #   #   |> Query.create(
  #   #     Vertex.new(q1a2.graph, -6, "Answer", %{text: "Parent / Guardian", value: "gaurdian"}),
  #   #     :a
  #   #   )
  #   #   |> Query.return(:a)
  #   #   |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #   #   |> Vertex.from()

  #   # q1a4 =
  #   #   Query.new()
  #   #   |> Query.create(
  #   #     Vertex.new(q1a3.graph, -7, "Answer", %{text: "Other", value: "other"}),
  #   #     :a
  #   #   )
  #   #   |> Query.return(:a)
  #   #   |> PostgrexAgtype.cypher_query!(conn, graph_name)
  #   #   |> Vertex.from()

  #   # query!(conn) do
  #   #   create(
  #   #     (node(:s, [:Survey], %{name: "Case Investigation"}) --
  #   #        rel([:Start]) ->
  #   #        node(:q, [:Question], %{
  #   #          type: "setting",
  #   #          key: "respondent",
  #   #          text: "Who is providing this information?"
  #   #        }))
  #   #   )
  #   # end

  #   # query!(conn) do
  #   #   match((node(:q) <- rel([:Start]) -- node(:s, [:Survey])))
  #   #   create(
  #   #     (node(:a1, [:Answer], %{text: "Case / Self", value: "self"}) --
  #   #       rel([:Answers]) ->
  #   #       node(:q))
  #   #     )
  #   #   create(
  #   #     (node(:a2, [:Answer], %{text: "Contact", value: "contact"}) --
  #   #       rel([:Answers]) ->
  #   #       node(:q))
  #   #     )
  #   #   create(
  #   #     (node(:a3, [:Answer], %{text: "Parent / Guardian", value: "guardian"}) --
  #   #       rel([:Answers]) ->
  #   #       node(:q))
  #   #     )
  #   #   create(
  #   #     (node(:a4, [:Answer], %{text: "Other", value: "other"}) --
  #   #       rel([:Answers]) ->
  #   #       node(:q))
  #   #     )
  #   # end

  #   # query!(conn) do
  #   #   match((node(:a, [:Answer]) -- rel([:Answers]) -> node([:Question])))
  #   #   return(:a)
  #   # end
  # end
end
