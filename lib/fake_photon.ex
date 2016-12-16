

require KeyRing
require Logger
require Crypto
require ComClient


defmodule FakePhoton do
  @doc """
  Fake photon device for testing.
  """

  @port 5632
  @host {192,168,0,192}
  @rsa_options [rsa_pad: :rsa_pkcs1_padding]
  @stm32id     << 0x37002a000447343337373739::12*8 >>
  @nonce_byte_length 40
  # 30 x 1000 milliseconds = 30 seconds
  @timeout 30*1000 


  def start() do
    opts = [active: false, packet: :raw, ip: @host]
    args = %{port: @port, opts: opts}
    ComClient.start_link(args)
    handshake(ComClient)
  end

  defp trace(packet) do
    IO.inspect packet
  end

  def handshake(com) do

    nonce = receive_nonce(com)
    :ok   = send_coreid(nonce, com)

    session_key = receive_session_key(com)
    :ok   = send_hello(session_key, com)

    com
  end


  # step one
  def receive_nonce(com) do
    {:ok, nonce} = com.recv(@nonce_byte_length, @timeout)
    to_string nonce
  end

  def send_coreid(nonce, com) do
    # encrypt_coreid(nonce, coreid, public_key, rsa_options)
    Logger.debug "sending coreid"
    message = nonce <> @stm32id
    server_public_key = KeyRing.load(public: :server)
    ciphertext = :public_key.encrypt_public(message, server_public_key, @rsa_options)
    com.send(ciphertext)
  end

  def receive_session_key(com) do
    msg_length = 384
    {:ok, packet} = com.recv(msg_length, @timeout)

    Logger.debug "packet size: #{byte_size(packet)} expected: #{msg_length}"

    #<< ciphertext::binary-size(128), signature::binary-size(256) >> = packet
    ciphertext = ""
    signature = ""

    server_public_key = KeyRing.load(public: :server)
    core_private_key = KeyRing.load(private: @stm32id)
    # get session_key
    session_key = :public_key.decrypt_private(ciphertext, core_private_key, @rsa_options)

    # check the signature on the session_key
    hmac_hash = :public_key.decrypt_public(signature, server_public_key, @rsa_options)
    ^hmac_hash = Crypto.create_hmac_digest(ciphertext, session_key)

    session_key
  end

  def send_hello(_session_key, com) do
    msg = "hello"
    com.send(msg)
    msg
  end

end

"""
 1.) Socket opens:

 2.) Server responds with 40 bytes of random data as a nonce.
     * Core should read exactly 40 bytes from the socket.
     Timeout: 30 seconds.  If timeout is reached, Core must close TCP socket and retry the connection.

     * Core appends the 12-byte STM32 Unique ID to the nonce, RSA encrypts the 52-byte message with the Server's public key,
     and sends the resulting 256-byte ciphertext to the Server.  The Server's public key is stored on the external flash chip at address TBD.
     The nonce should be repeated in the same byte order it arrived (FIFO) and the STM32 ID should be appended in the
     same byte order as the memory addresses: 0x1FFFF7E8, 0x1FFFF7E9, 0x1FFFF7EA… 0x1FFFF7F2, 0x1FFFF7F3.

 3.) Server should read exactly 256 bytes from the socket.
     Timeout waiting for the encrypted message is 30 seconds.  If the timeout is reached, Server must close the connection.

     * Server RSA decrypts the message with its private key.  If the decryption fails, Server must close the connection.
     * Decrypted message should be 52 bytes, otherwise Server must close the connection.
     * The first 40 bytes of the message must match the previously sent nonce, otherwise Server must close the connection.
     * Remaining 12 bytes of message represent STM32 ID.  Server looks up STM32 ID, retrieving the Core's public RSA key.
     * If the public key is not found, Server must close the connection.

 4.) Server creates secure session key
     * Server generates 40 bytes of secure random data to serve as components of a session key for AES-128-CBC encryption.
     The first 16 bytes (MSB first) will be the key, the next 16 bytes (MSB first) will be the initialization vector (IV), and the final 8 bytes (MSB first) will be the salt.
     Server RSA encrypts this 40-byte message using the Core's public key to create a 128-byte ciphertext.
     * Server creates a 20-byte HMAC of the ciphertext using SHA1 and the 40 bytes generated in the previous step as the HMAC key.
     * Server signs the HMAC with its RSA private key generating a 256-byte signature.
     * Server sends 384 bytes to Core: the ciphertext then the signature.


 5.) Release control back to the SparkCore module

     * Core creates a protobufs Hello with counter set to the uint32 represented by the most significant 4 bytes of the IV, encrypts the protobufs Hello with AES, and sends the ciphertext to Server.
     * Server reads protobufs Hello from socket, taking note of counter.  Each subsequent message received from Core must have the counter incremented by 1. After the max uint32, the next message should set the counter to zero.

     * Server creates protobufs Hello with counter set to a random uint32, encrypts the protobufs Hello with AES, and sends the ciphertext to Core.
     * Core reads protobufs Hello from socket, taking note of counter.  Each subsequent message received from Server must have the counter incremented by 1. After the max uint32, the next message should set the counter to zero.
"""
