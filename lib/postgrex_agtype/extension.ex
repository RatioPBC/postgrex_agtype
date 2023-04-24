defmodule PostgrexAgtype.Extension do
  @moduledoc """
  Implementation of Postgrex.Extension supporting `agtype`.
  """

  @behaviour Postgrex.Extension

  # @impl true
  # def decode(_) do
  #   quote location: :keep do
  #     # length header is in bytes
  #     <<len::signed-32, integer::signed-size(len)-unit(8)>> ->
  #       integer
  #   end
  # end

  # @impl true
  # def encode(_) do
  #   quote location: :keep do
  #     integer ->
  #       <<8::signed-32, integer::signed-64>>
  #   end
  # end

  @impl true
  def format(_), do: :binary

  # @impl true
  # def init(opts) do
  #   Keyword.get(opts, :decode_copy, :copy)
  # end

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

        if String.ends_with?(copied, "::numeric") do
          copied
          |> String.slice(0..-10)
          |> Decimal.new()
        else
          unquote(library).decode!(copied)
        end
    end
  end

  def decode({library, :reference}) do
    quote location: :keep do
      <<len::int32(), data::binary-size(len)>> ->
        <<1, json::binary>> = data
        unquote(library).decode!(json)
    end
  end
end
