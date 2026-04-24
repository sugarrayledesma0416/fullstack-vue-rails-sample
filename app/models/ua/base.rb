module Ua
  class Base < ActiveResource::Base
    self.site = UA_URL
    self.user = Rails.configuration.ua_api_username
    self.password = Rails.configuration.ua_api_password
    self.format = :json
    self.prefix = '/m3/'
    self.include_root_in_json = false
  end
end
