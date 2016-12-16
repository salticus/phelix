
require Logger


defmodule ComClient do
  @doc """
  Wrap tcp socket for easier testing.
  """
  use GenServer

  @host {192,168,0,192}
  @port 5683
  @tcp_opts [active: false, packet: :raw]

  # external API
  def start_link(%{host: @host, port: port, opts: opts}) do
    GenServer.start_link(__MODULE__, %{host: @host, port: port, opts: opts}, name: __MODULE__)
  end

  def recv(num_bytes, timeout) do
    args = %{num_bytes: num_bytes, timeout: timeout}
    GenServer.call(__MODULE__, args)
  end

  def send(message) do
    GenServer.call(__MODULE__, %{message: message})
  end

  # internal callbacks
  def init(%{port: port, opts: opts}) do
    Logger.debug("Connect to #{port}")
    {:ok, socket} = :gen_tcp.connect(port, opts)
    {:ok, socket}
  end

  def handle_call(%{num_bytes: num_bytes, timeout: timeout}, from, socket) do
    {:ok, message} = :gen_tcp.recv(socket, num_bytes, timeout)
    {:reply, {:ok, message}, socket}
  end

  def handle_call(%{message: message}, from, socket) do
    :ok = :gen_tcp.send(socket, message)
    {:reply, :ok, socket}
  end
end
