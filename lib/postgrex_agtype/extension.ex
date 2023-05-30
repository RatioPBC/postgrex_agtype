defmodule PostgrexAgtype.Extension do
  @moduledoc """
  Implementation of Postgrex.Extension supporting `agtype`.
  """

  @behaviour Postgrex.Extension

  alias Age.{Edge, Graph, Vertex}

  @impl true
  def format(_), do: :binary

  @impl true
  def matching(_), do: [type: "agtype"]

  @impl true
  def init(opts) do
    json =
      Keyword.get_lazy(opts, :json, fn ->
        Application.get_env(:postgrex, :json_library, Jason)
      end)

    {json, Keyword.get(opts, :decode_binary, :copy)}
  end

  @impl true
  def encode({library, _}) do
    quote location: :keep do
      map ->
        data = unquote(library).encode_to_iodata!(map)
        [<<IO.iodata_length(data) + 1::int32(), 1>> | data]
    end
  end

  @impl true
  def decode({library, :copy}) do
    quote location: :keep do
      <<len::int32(), data::binary-size(len)>> ->
        <<1, json::binary>> = data

        copied = :binary.copy(json)
        lib = unquote(library)

        cond do
          String.ends_with?(copied, "::numeric") ->
            PostgrexAgtype.Extension.handle_agtype_numeric(copied)

          Regex.match?(~r/::/, copied) ->
            PostgrexAgtype.Extension.handle_agtype(copied, lib)

          true ->
            lib.decode!(copied)
        end
    end
  end

  @spec handle_agtype(String.t(), module()) ::
          Age.entity() | map() | list() | String.t() | integer() | float() | boolean()
  def handle_agtype(json, lib) do
    result =
      json
      |> String.trim_trailing("::path")
      |> replace_agtype()
      |> lib.decode!()

    cond do
      is_list(result) ->
        build_graph(result)

      is_map(result) and Map.has_key?(result, "_agtype") ->
        convert_agtype(result)

      true ->
        replace_decimal_values(result)
    end
  end

  @spec build_graph(list(), Graph.t()) :: Graph.t()
  def build_graph(entities, graph \\ %Graph{})

  def build_graph([], graph), do: graph

  def build_graph([entity | rest], graph) do
    graph =
      case convert_agtype(entity) do
        %Edge{} = edge ->
          Graph.add_edge(graph, edge)

        %Vertex{} = vertex ->
          Graph.add_vertex(graph, vertex)
      end

    build_graph(rest, graph)
  end

  @spec convert_agtype(map()) :: Age.entity()
  defp convert_agtype(%{"_agtype" => "vertex"} = entity) do
    %Vertex{
      id: entity["id"],
      label: entity["label"],
      properties: replace_decimal_values(entity["properties"])
    }
  end

  defp convert_agtype(%{"_agtype" => "edge"} = entity) do
    %Edge{
      v1: entity["start_id"],
      v2: entity["end_id"],
      id: entity["id"],
      label: entity["label"],
      properties: replace_decimal_values(entity["properties"])
    }
  end

  defp convert_agtype(entity),
    do: raise ArgumentError, "_agtype key not found in #{inspect(entity)}"

  @doc """
  Translates PostgreSQL numeric (as indicated by AGE with `::numeric` cast) to
  Decimal.

  Exported because extension code is macro-based, so this will be called from
  other modules.
  """
  @spec handle_agtype_numeric(String.t()) :: Decimal.t()
  def handle_agtype_numeric(json) do
    json
    |> String.trim_trailing("::numeric")
    |> Decimal.new()
  end

  @spec replace_agtype(String.t()) :: String.t()
  defp replace_agtype(json) do
    json
    |> String.replace(~r/(\d+(\.\d+)?)::numeric/, ~s("\\1"))
    |> String.replace(~r/}::(vertex|edge)/, ~s(,"_agtype":"\\1"}))
  end

  @spec replace_decimal_values(map()) :: map()
  defp replace_decimal_values(map) do
    Enum.reduce(map, %{}, fn
      {k, v}, m when is_map(v) ->
        Map.put(m, k, replace_decimal_values(v))

      {k, v}, m when is_binary(v) ->
        v = if Regex.match?(~r/^\d+(\.\d+)?$/, v), do: Decimal.new(v), else: v
        Map.put(m, k, v)

      {k, v}, m ->
        Map.put(m, k, v)
    end)
  end
end
