class Encoder
  include Singleton

  # def encode text
  #   text = text.to_s unless text.is_a? String

  #   encoded = Base64.encode64(text).strip
  #   hash = checksum text

  #   "#{encoded}$$#{hash}"
  # end

  # def decode string
  #   return if string.blank?

  #   encoded, hash = string.to_s.split '$$'
  #   text = Base64.decode64(encoded).force_encoding('utf-8')

  #   text if hash == checksum(text)
  # end

  def checksum text
    Digest::SHA256.hexdigest(text.to_s + secret_key_base)
  end

  def valid? text:, hash:
    checksum(text) == hash
  end

private

  def secret_key_base
    Rails.application.secrets.secret_key_base
  end
end
# sometime it generates non decryptable texts on production. dunny why
# class Encryptor
#   include Singleton

#   def encrypt text
#     text = text.to_s unless text.is_a? String

#     salt = SecureRandom.hex key_len
#     key = key_generator.generate_key salt, key_len
#     crypt = ActiveSupport::MessageEncryptor.new key
#     encrypted_data = crypt.encrypt_and_sign text

#     "#{salt}$$#{encrypted_data}"
#   end

#   def decrypt text
#     return if text.blank?

#     salt, data = text.to_s.split '$$'

#     key = key_generator.generate_key salt, key_len
#     crypt = ActiveSupport::MessageEncryptor.new key

#     crypt.decrypt_and_verify data
#   rescue ActiveSupport::MessageVerifier::InvalidSignature
#   end

# private

#   def key_generator
#     @key_generator ||= ActiveSupport::KeyGenerator.new secret_key_base
#   end

#   def secret_key_base
#     Rails.application.secrets.secret_key_base
#   end

#   def key_len
#     ActiveSupport::MessageEncryptor.key_len
#   end
# end
