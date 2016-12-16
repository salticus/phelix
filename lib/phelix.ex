
require Protocol.Supervisor


defmodule Phelix do
  use Application

  def start(_, _) do

    Protocol.Supervisor.start_link(__MODULE__, :ok)
  end

end
