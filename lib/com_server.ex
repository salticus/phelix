require Logger

defmodule ComServer do
  @doc """
  Wrap tcp socket for easier testing.
  """
  use GenServer

  @host 'localhost'
  @port 9090
  @tcp_opts [active: false, packet: :raw]

  # external API
  def start_link(%{port: port, opts: opts}) do
    args = %{port: port, opts: opts}
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_link(%{host: host, port: port, opts: opts}) do
    opts = opts ++ [ip: host]
    args = %{port: port, opts: opts}
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def accept(timeout \\ :infinity) do
    GenServer.call(__MODULE__, :accept, timeout)
  end

  def recv(num_bytes, timeout) do
    message = GenServer.call(__MODULE__, %{num_bytes: num_bytes, timeout: timeout})
    {:ok, message}
  end

  def send(message) do
    GenServer.call(__MODULE__, %{message: message})
  end

  # internal callbacks
  def init(%{port: port, opts: opts}) do
    Logger.info "Listening on #{port}"
    {:ok, socket} = :gen_tcp.listen(port, opts)
    {:ok, socket}
  end

  def init(%{port: port, opts: opts}) do
    Logger.info "Listening on #{port}"
    {:ok, socket} = :gen_tcp.listen(port, opts)
    {:ok, socket}
  end

  def handle_call(%{num_bytes: num_bytes, timeout: timeout}, from, socket) do
    answer = {:ok, message} = :gen_tcp.recv(socket, num_bytes, timeout)
    {:reply, answer, socket}
  end

  def handle_call(%{message: message}, from, socket) do
    :ok = :gen_tcp.send(socket, message)
    {:reply, :ok, socket}
  end

  def handle_call(:accept, from, socket) do
    answer = {:ok, connection} = :gen_tcp.accept(socket)
    {:reply, :connected, connection}
  end

end
