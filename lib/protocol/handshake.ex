require Logger
require KeyRing
require Crypto
require ComServer


# TODO remove
require Crutch


defmodule Protocol.Handshake do
  @nonce_byte_size 40
  @rsa_options [{:rsa_pad, :rsa_pkcs1_padding}]
  @timeout 30*1000

  def handshake(com) do
    nonce       = send_nonce(com)
    stm32id     = receive_coreid(nonce, com)

    session_key = send_session_key(stm32id, com)

    core_count  = receive_hello(session_key, com)
    server_count  = send_hello(session_key, com)

    {core_count, server_count}
  end

  def send_nonce(com) do
    # 2 Server sends 40 bytes random data as a nonce
    nonce = :crypto.strong_rand_bytes(@nonce_byte_size)
    :ok = com.send(nonce)
    Logger.info "nonce sent"
    nonce
  end

  def receive_coreid(nonce, com) do
    # 3.) Server should read s/exactly/at least/ 256 bytes from the socket.
    # Timeout waiting for the encrypted message is 30 seconds.  If the timeout is reached, Server must close the connection.
    # 
    # * Server RSA decrypts the message with its private key.  If the decryption fails, Server must close the connection.
    # * Decrypted message should be at least 52 bytes, otherwise Server must close the connection.
    # * The first 40 bytes of the message must match the previously sent nonce, otherwise Server must close the connection.
    # * Remaining 12 bytes of message represent STM32 ID.  Server looks up STM32 ID, retrieving the Core's public RSA key.
    # * If the public key is not found, Server must close the connection.

    server_private_key = KeyRing.load(private: :server)
    msg_length = 256
    timeout = 30*1000 # 30 x 1000 ms
    # todo, handle error case and closing socket
    {:ok, packet} = com.recv(msg_length, timeout)
    plaintext = :public_key.decrypt_private(packet, server_private_key, @rsa_options)
    << nonce_in::binary-size(40), stm32id::binary-size(12) >> = plaintext
    ^nonce = nonce_in
    Logger.info "received connection from #{stm32id}"

    stm32id
  end

  def send_session_key(stm32id, com) do
    #4.) Server creates secure session key
    #* Server generates 40 bytes of secure random data to serve as components of a session key for AES-128-CBC encryption.
    #The first 16 bytes (MSB first) will be the key, the next 16 bytes (MSB first) will be the initialization vector (IV), and the final 8 bytes (MSB first) will be the salt.
    #Server RSA encrypts this 40-byte message using the Core's public key to create a 128-byte ciphertext.
    #* Server creates a 20-byte HMAC of the ciphertext using SHA1 and the 40 bytes generated in the previous step as the HMAC key.
    #* Server signs the HMAC with its RSA private key generating a 256-byte signature.
    #* Server sends 384 bytes to Core: the ciphertext then the signature.

    #Logger.debug "send_session_key: #{stm32id}, #{com}" # neither of those things are formattable

    Crutch.show_type stm32id, "stm32id"

    core_public_key     = KeyRing.load(public: stm32id)
    server_private_key  = KeyRing.load(private: :server)


    session_key = :crypto.strong_rand_bytes(40)
    ciphertext = :public_key.encrypt_public(session_key, core_public_key, @rsa_options)
    hash = Crypto.create_hmac_digest(ciphertext, session_key)
    signature = :public_key.encrypt_private(hash, server_private_key, @rsa_options)
    :ok = com.send(ciphertext <> signature)

    Logger.info "send session key"
    session_key
  end


   # the code shows the server using coap for communication

   #5.) Release control back to the SparkCore module
   #
   #* Core creates a protobufs Hello with counter set to the uint32 represented by the most significant 4 bytes of the IV, encrypts the protobufs Hello with AES, and sends the ciphertext to Server.
   #* Server reads protobufs Hello from socket, taking note of counter.  Each subsequent message received from Core must have the counter incremented by 1. After the max uint32, the next message should set the counter to zero.
   #
   #* Server creates protobufs Hello with counter set to a random uint32, encrypts the protobufs Hello with AES, and sends the ciphertext to Core.
   #* Core reads protobufs Hello from socket, taking note of counter.  Each subsequent message received from Server must have the counter incremented by 1. After the max uint32, the next message should set the counter to zero.
   def receive_hello(_session_key, com) do
     {:ok, hello} = com.recv(0, @timeout)
     # todo parse hello from coap
     Logger.info "receive hello"
     hello
  end

  def send_hello(_session_key, com) do
    msg = "hello"
    :ok = com.send(msg)
     Logger.info "send hello"
    msg
  end

end


