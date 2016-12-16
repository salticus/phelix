
defmodule Stub do
  def read_stub(stub_path) do
    {:ok, f} = File.open(stub_path, [:binary, :read])
      # gotcha: you have to use IO.binread with File.open(_, [:binary])
      # and :binary is the default
      stub = IO.binread(f, :all)
    File.close f
    stub
  end
end
