class XapiUserToken
  # A token can be instantiated either for encoding or decoding. When
  # instantiating for encoding, the attributes that should be encoded into it
  # are specified. For decoding, the encoded form (aka mbox) is specified.
  def initialize(token_attrs)
    if token_attrs.key?(:mbox)
      @mbox = token_attrs[:mbox]
    else
      @attrs = token_attrs.slice(:attempt_id, :user_id, :state_modifiable)
    end
  end

  def attrs
    return @attrs if defined? @attrs
    @attrs = attrs_from_mbox(@mbox)
  end

  def attempt_id
    attrs[:attempt_id]
  end

  def user_id
    attrs[:user_id]
  end

  def state_modifiable
    attrs[:state_modifiable]
  end

  def mbox
    return @mbox if defined? @mbox
    @mbox = generate_mbox(attempt_id, user_id, state_modifiable)
  end

  private def generate_mbox(attempt_id, user_id, state_modifiable)
    attrs = {
      attempt_id: attempt_id,
      user_id: user_id,
      state_modifiable: state_modifiable
    }
    token = encrypt(attrs.to_json)
    # TODO: Add some prefix and suffix
    Base64.urlsafe_encode64(token)
  end

  private def attrs_from_mbox(mbox)
    email_base_64 = mbox.sub(/^mailto:/, '')
    email = Base64.urlsafe_decode64(email_base_64)
    JSON.parse(decrypt(email), symbolize_names: true)
  rescue ArgumentError,
         JSON::ParserError,
         ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveSupport::MessageEncryptor::InvalidMessage
    # - When the mbox is not a valid base64 encoded string, it raises ArgumentError.
    # - When the mbox has an invalid signature, it raises
    #   ActiveSupport::MessageVerifier::InvalidSignature
    # - When the mbox cannot be decrypted or verified, it raises
    #   ActiveSupport::MessageEncryptor::InvalidMessage
    # - When the decrypted mbox can't be parsed as JSON, it raises JSON::ParserError
    # In all these cases, we return an empty hash of attributes
    {}
  end

  # We don't encrypt secure info, so we don't use any salt.
  # But we could add some salt doing something like this:
  #   salt = SecureRandom.random_bytes(64)
  #   key = ActiveSupport::KeyGenerator.new(key_base).generate_key(salt)
  #   encryptor = ActiveSupport::MessageEncryptor.new(key)
  #   encrypted_data = crypt.encrypt_and_sign(msg)
  #   "#{salt}$$#{encrypted_data}
  private def encrypt(msg)
    encryptor = ActiveSupport::MessageEncryptor.new(key_base)
    encryptor.encrypt_and_sign(msg)
  end

  # Decrypt the info and deserialize it
  # If we add some salt, the method would look like:
  #   salt, encrypted_data = msg.split '$$'
  #   key = ActiveSupport::KeyGenerator.new(key_base).generate_key(salt)
  #   encryptor = ActiveSupport::MessageEncryptor.new(key_base)
  #   encryptor.decrypt_and_verify(msg)
  private def decrypt(msg)
    encryptor = ActiveSupport::MessageEncryptor.new(key_base)
    encryptor.decrypt_and_verify(msg)
  end

  private def key_base
    Rails.application.config.xapi_encryption_key
  end
end
