require_relative './vitalsource/config'

module Vitalsource
  def request_sso_url(user, book_id, program_id, expiration_date)
    ReferenceUser.new(user).access_token do |access_token|
      License.new(access_token, book_id, expiration_date).ensure_access do
        VitalsourceRedemption.create!(user_id: user.id, program_id: program_id)
        Redirect.new(access_token, book_id).sso_url
      end
    end
  end
  module_function :request_sso_url

  def self.config
    @config
  end

  def self.configure
    @config ||= Config.new
    yield @config
  end
end
