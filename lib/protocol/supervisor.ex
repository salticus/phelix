
require Protocol.Server


defmodule Protocol.Supervisor do
  use Supervisor

  def start_link(_module, _args) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Protocol.Server, [Protocol.Server, []], [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
