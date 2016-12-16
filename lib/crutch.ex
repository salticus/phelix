
require Logger


defmodule Crutch do

  def show_type(var, name \\ "var") do
    t = case var do
      var when is_atom(var) -> "#{name} is_atom"
      var when is_binary(var) -> "#{name} is_binary"
      var when is_bitstring(var) -> "#{name} is_bitstring"
      var when is_boolean(var) -> "#{name} is_boolean"
      var when is_float(var) -> "#{name} is_float"
      var when is_function(var) -> "#{name} is_function"
      #var when is_function(var, arity)[ -> "#{name} is_function"
      var when is_integer(var) -> "#{name} is_integer"
      var when is_list(var) -> "#{name} is_list"
      var when is_map(var) -> "#{name} is_map"
      var when is_number(var) -> "#{name} is_number"
      var when is_pid(var) -> "#{name} is_pid"
      var when is_port(var) -> "#{name} is_port"
      var when is_reference(var) -> "#{name} is_reference"
      var when is_tuple(var) -> "#{name} is_tuple"
    end
    Logger.debug t
  end

end

