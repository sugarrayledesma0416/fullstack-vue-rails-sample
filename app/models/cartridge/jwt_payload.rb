module Cartridge
  module JWTPayload
    # jwt made up of 3 '.' separated strings -
    # header
    # payload - e.g. launch params from UA
    # signature
    def decode(jwt)
      # loop through the possible secrets;
      # any one of these could have been used by UA to encode the JWT
      decoded_token = []
      # break at the first secret that successfully decodes the token
      # values can be either an array (dev, qa) or
      # an array of arrays (prod) depending on env
      # so need to flatten into single array
      HTTP_AUTHENTICATIONS.values.flatten.map do |secret|
        decoded_token = JWT.decode jwt, secret, true, { :algorithm => 'HS256' }
        break
      rescue JWT::VerificationError => e
      end
      # decoded_token is an array of hashes; we want to return
      # one big one with all the pairs merged
      decoded_token.each_with_object({}) do |pair, hash|
        hash.merge!(pair)
      end
    end
    module_function :decode
  end
end