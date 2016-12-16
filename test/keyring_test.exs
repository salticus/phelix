
defmodule KeyRingTest do
  use ExUnit.Case
  doctest KeyRing

  test "server key" do
    public = KeyRing.load(public: :server)
    private = KeyRing.load(private: :server)

    msg = "shibboleth"

    ciphertext = :public_key.encrypt_public(msg, public)
    ^msg = :public_key.decrypt_private(ciphertext, private)
  end

  test "server key with pkcs1_padding" do
    public = KeyRing.load(public: :server)
    private = KeyRing.load(private: :server)

    msg = "shibboleth"
    options = [{:rsa_pad, :rsa_pkcs1_oaep_padding}]

    ciphertext = :public_key.encrypt_public(msg, public, options)
    ^msg = :public_key.decrypt_private(ciphertext, private, options)

  end

  test "vet_key_path" do
    public = KeyRing.load(public: :server)
    private = KeyRing.load(private: :server)
    numerals = "37002a000447343337373739"
    coreid = << 0x37002a000447343337373739::8*12 >>

    ^numerals = KeyRing.convert_to_hex_numerals(coreid)
  end
end
