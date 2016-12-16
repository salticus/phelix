#!/usr/bin/env elixir

require Crutch
require Logger

defmodule KeyRing do
  @doc """
  Handle loading and parsing keys from the keystore.
  """

  @keypath "./keys/"

  def load([{type, :server}]) do
    load_key("#{@keypath}server.#{type}.pem")
  end

  def load([{type, :server}]) do
    load_key("#{@keypath}server.#{type}.pem")
  end

  def load([{type, << tag::12*8 >>}]) do
    Crutch.show_type tag
    path = convert_to_hex_numerals(tag)
    load_key("#{@keypath}#{path}.#{type}.pem")
  end

  def convert_to_hex_numerals(tag) when is_integer(tag) do
    Logger.debug "tag: #{tag}"
    :erlang.integer_to_binary(tag, 16) |> String.downcase
  end

  def convert_to_hex_numerals(<< tag::binary-size(12) >>) do
    seq = for << ch::4 <- tag >>, do: Integer.to_string(ch, 16)
    path = seq |> Enum.join |> String.downcase
    path
  end

  def load_key(key_path) do
    Logger.debug "key_path: #{key_path}"
    {:ok, binfile} = :file.read_file(key_path)
    [entry] = :public_key.pem_decode(binfile)
    key = :public_key.pem_entry_decode(entry)
    key
  end
end
