#!/usr/bin/env elixir

require Logger
require ComServer
require Protocol.Handshake


defmodule Protocol.Server do
  @port 5683
  @host_ip { 192,168,0,192 }

  def start_link() do
    opts = [active: false, packet: :raw, ip: @host_ip]
    ComServer.start_link(%{port: @port, opts: opts})
    loop_accept()
  end

  def loop_accept() do
    ComServer.accept()
    Logger.info("Accepted connection")
    Protocol.Handshake.handshake(ComServer)
    Logger.info("Handshake successful")
    loop_accept()
  end

  def stop(_ref) do
    timeout = 5*1000
    ComServer.stop(ComServer, :shutdown, timeout)
  end

end
