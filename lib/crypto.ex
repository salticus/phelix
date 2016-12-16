

defmodule Crypto do
  @doc """
  Handle hashing and cryptography for the spark server replacement.
  """

  def create_hmac_digest(ciphertext, key) do
    # guessing that sha is sha1
    # NOTE: docs warn against using a hash context more than once (at risk of
    # crashing the VM: apparently the interop between SSL and erlang can be
    # rough.)
    context = :crypto.hmac_init(:sha, key)
    new_context = :crypto.hmac_update(context, ciphertext)
    :crypto.hmac_final(new_context)
  end


end
