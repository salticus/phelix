

require FakeCom


defmodule FakePhotonTest do
  use ExUnit.Case
  
  setup do
    FakeCom.start_link()
    :ok
  end

  test "recieve nonce" do
    nonce = "it's an occasionalism!"
    FakeCom.send(nonce)
    ^nonce = FakePhoton.receive_nonce(FakeCom)
  end

  test "send coreid" do
    nonce = :crypto.strong_rand_bytes(40)
    FakePhoton.send_coreid(nonce, FakeCom)
    {:ok, ciphertext} = FakeCom.recv(nil, nil)
  end

end

