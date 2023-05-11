defmodule PostgrexAgtype.Examples.Survey do
  @moduledoc false

  # import ExCypher, only: [cypher: 1]

  alias PostgrexAgtype.DataCase

  @dialyzer {:nowarn_function, setup: 0}

  @graph "postgrexagtype_test"

  defmacro query!(conn, do: block) do
    quote do
      %Postgrex.Result{rows: rows} =
        PostgrexAgtype.query!(unquote(conn), @graph, cypher(do: unquote(block)))

      case rows do
        [[result]] ->
          result

        [] ->
          nil
      end
    end
  end

  def setup do
    %{conn: conn} = DataCase.setup_postgrex(nil)
    DataCase.create_graph(%{conn: conn})

    # query!(conn) do
    #   create(
    #     (node(:s, [:Survey], %{name: "Case Investigation"}) --
    #        rel([:Start]) ->
    #        node(:q, [:Question], %{
    #          type: "setting",
    #          key: "respondent",
    #          text: "Who is providing this information?"
    #        }))
    #   )
    # end

    # query!(conn) do
    #   match((node(:q) <- rel([:Start]) -- node(:s, [:Survey])))
    #   create(
    #     (node(:a1, [:Answer], %{text: "Case / Self", value: "self"}) --
    #       rel([:Answers]) ->
    #       node(:q))
    #     )
    #   create(
    #     (node(:a2, [:Answer], %{text: "Contact", value: "contact"}) --
    #       rel([:Answers]) ->
    #       node(:q))
    #     )
    #   create(
    #     (node(:a3, [:Answer], %{text: "Parent / Guardian", value: "guardian"}) --
    #       rel([:Answers]) ->
    #       node(:q))
    #     )
    #   create(
    #     (node(:a4, [:Answer], %{text: "Other", value: "other"}) --
    #       rel([:Answers]) ->
    #       node(:q))
    #     )
    # end

    # query!(conn) do
    #   match((node(:a, [:Answer]) -- rel([:Answers]) -> node([:Question])))
    #   return(:a)
    # end
  end
end
