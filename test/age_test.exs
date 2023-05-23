defmodule AgeTest do
  use ExUnit.Case, async: true
  doctest Age

  describe "wrap_properties/1" do
    test "raises on invalid values" do
      assert_raise ArgumentError, fn ->
        Age.wrap_properties(%{})
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties([])
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(true)
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(123)
      end

      assert_raise ArgumentError, fn ->
        Age.wrap_properties(123.45)
      end
    end
  end

  describe "quote_string/1" do
    test "raises on invalid values" do
      assert_raise ArgumentError, fn ->
        Age.quote_string(%{})
      end

      assert_raise ArgumentError, fn ->
        Age.quote_string([])
      end
    end
  end
end
