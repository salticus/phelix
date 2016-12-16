
require FakeCom

defmodule Protocol.HandshakeTest do
  @coreid  << 0x37002a000447343337373739::12*8 >>
  use ExUnit.Case

  @doc """
  test "decrypt" do
    nonce_stub = Stub.read_stub("_runs/1466289822718-0-__server_sends__nonce")
    packet = Stub.read_stub("./_runs/1466289822718-1__core_sends__coreid")
    rsa_private_key_file = "./_runs/default_key.pem"
    coreid = << 0x37002a000447343337373739::12*8 >>

    #  node library ursa.generatePrivateKey(bits=2048, exponent=65537)

    {:ok, result} = Protocol.Handshake.decrypt(packet, rsa_private_key_file)
    << nonce_out::binary-size(40), coreid_out::binary-size(12),  r::binary >> = result
    ^nonce_out = nonce_stub
    ^coreid_out = coreid
  end


  test "secure_session_key" do
    iv = Stub.read_stub("_runs/y/1467513075325-3__40byte-sessionKey-sessionKey")
    server_private_key = Stub.read_stub("./_runs/keys/server-private.pem")
    server_public_key = Stub.read_stub("./_runs/keys/server-public.pem")
    core_private_key = Stub.read_stub("./_runs/keys/core-private.pem")
    core_public_key = Stub.read_stub("./_runs/keys/core-public.pem")

    << ciphertext::binary-size(128), signature::binary-size(256) >> = Protocol.Handshake.secure_session_key(iv, server_private_key, core_public_key)
    # check signature
    ^ciphertext = :public_key.decrypt_public(signature, server_public_key, rsa_padding: :rsa_pkcs1_padding)
    # get initialization vector
    ^iv = :public_key.decrypt_private(ciphertext, core_private_key, rsa_padding: :rsa_pkcs1_padding)
  end
  """
  
  setup do
    FakeCom.start_link()
    :ok
  end

  test "send nonce" do
    << nonce::binary-size(40) >> = Protocol.Handshake.send_nonce(FakeCom)
    {:ok, message} = FakeCom.recv(nil, nil)
    ^nonce = message
  end

  test "handshake protocol" do
    com = FakeCom

    << nonce::binary-size(40) >> = Protocol.Handshake.send_nonce(com)

    ^nonce  = FakePhoton.receive_nonce(com)
    :ok     = FakePhoton.send_coreid(nonce, com)

    stm32id     = Protocol.Handshake.receive_coreid(nonce, com)
    session_key = Protocol.Handshake.send_session_key(stm32id, com)

    ^session_key = FakePhoton.receive_session_key(com)
    #core_counter = FakePhoton.send_hello(session_key, com)

    #^core_counter = Protocol.Handshake.receive_hello(session_key, com)
    #cloud_counter = Protocol.Handshake.send_hello(session_key, com)
  end
end
