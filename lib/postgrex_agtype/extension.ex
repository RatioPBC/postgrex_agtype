defmodule PostgrexAgtype.Extension do
  @moduledoc """
  Implementation of Postgrex.Extension supporting `agtype`.
  """

  @behaviour Postgrex.Extension

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
          Graph.t() | map() | list() | String.t() | integer() | float() | boolean()
  def handle_agtype(json, lib) do
    result =
      json
      |> String.trim_trailing("::path")
      |> replace_agtype()
      |> lib.decode!()

    cond do
      is_list(result) ->
        build_path(result)

      is_map(result) and Map.has_key?(result, "_agtype") ->
        convert_agtype(result, Graph.new())

      true ->
        replace_decimal_values(result)
    end
  end

  @spec build_path(list()) :: Graph.t()
  defp build_path(path), do: build_path(path, [], Graph.new())

  @spec build_path(list(), list(), Graph.t()) :: Graph.t()
  defp build_path([], [], graph), do: graph

  defp build_path([], [edge | rest], graph) do
    graph = convert_agtype(edge, graph)

    build_path([], rest, graph)
  end

  defp build_path([entity | rest], edges, graph) do
    case Map.fetch(entity, "_agtype") do
      {:ok, "vertex"} ->
        graph = convert_agtype(entity, graph)

        build_path(rest, edges, graph)

      {:ok, "edge"} ->
        build_path(rest, [entity | edges], graph)

      :error ->
        raise ArgumentError, "_agtype key not found"
    end
  end

  @spec convert_agtype(map(), Graph.t()) :: Graph.t()
  defp convert_agtype(%{"_agtype" => "vertex"} = entity, graph) do
    label =
      entity
      |> Map.take(["label", "properties"])
      |> replace_decimal_values()

    Graph.add_vertex(graph, Map.fetch!(entity, "id"), label)
  end

  defp convert_agtype(%{"_agtype" => "edge"} = entity, graph) do
    label =
      entity
      |> Map.drop(["_agtype", "start_id", "end_id"])
      |> replace_decimal_values()

    edge =
      Graph.Edge.new(
        Map.fetch!(entity, "start_id"),
        Map.fetch!(entity, "end_id"),
        label: label
      )

    Graph.add_edge(graph, edge)
  end

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
